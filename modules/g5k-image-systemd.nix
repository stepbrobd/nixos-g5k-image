{ config
, lib
, pkgs
, modulesPath
, ...
}:
let
  image_name = "nixos-${pkgs.stdenv.hostPlatform.system}";

  arch = pkgs.stdenv.hostPlatform.uname.processor;

  author = "";

  file_image_baseurl = "g5k-image";

  postinstall = "http://public.grenoble.grid5000.fr/~orichard/postinstalls/g5k-postinstall";
  #"server:///grid5000/postinstalls/g5k-postinstall.tgz";

  postinstall_args = "g5k-postinstall --net none --bootloader no-grub-from-deployed-env";

in
{
  imports = [
    # Profiles of this basic installation.
    "${modulesPath}/profiles/all-hardware.nix"
    "${modulesPath}/profiles/base.nix"
    "${modulesPath}/profiles/installation-device.nix"
    "${modulesPath}/installer/scan/not-detected.nix"
  ];

  options = { };

  config = {
    networking.hostName = "";
    # base configuration
    services.sshd.enable = true;
    networking.firewall.enable = false;

    services.openssh.settings.PermitRootLogin = lib.mkDefault "yes";
    services.getty.autologinUser = lib.mkDefault "root";

    # For debugging if a systmed's unit failed
    #boot.initrd.systemd.emergencyAccess = true;

    # Disable systemd for stage 1
    #boot.initrd.systemd.enable = false;

    # Use the GRUB 2 boot loader.
    boot.loader.grub.enable = true;
    boot.loader.grub.device = "/dev/root";

    boot.initrd.availableKernelModules = [
      "ahci"
      "ehci_pci"
      "megaraid_sas"
      "sd_mod"
    ];
    boot.kernelModules = lib.optionals pkgs.stdenv.hostPlatform.isx86 [ "kvm-intel" "kvm-amd" ];

    fileSystems."/" = {
      device = "/dev/root";
      fsType = "ext4";

    };

    # boot.initrd.systemd.services.remount-sysroot-rw = {
    #   description = "Remount /sysroot en rw";
    #   wantedBy = [ "initrd.target" ];
    #   after = [ "initrd-root-fs.target" ];
    #   serviceConfig = {
    #     Type = "oneshot";
    #     ExecStart = "${pkgs.util-linux}/bin/mount -o remount,rw /sysroot";
    #   };
    # }; 


    swapDevices = [ ];
    system.stateVersion = lib.mkDefault lib.trivial.release;

    system.build.g5k-image-archive = import "${toString modulesPath}/../lib/make-system-tarball.nix" {
      fileName = image_name;
      stdenv = pkgs.stdenv;
      closureInfo = pkgs.closureInfo;
      pixz = pkgs.pixz;
      extraCommands = "mkdir -p etc/ssh root tmp var/log";
      storeContents = [
        {
          object = config.system.build.toplevel;
          symlink = "/run/current-system";
        }
      ];

      contents = [
        {
          source = config.system.build.initialRamdisk + "/" + config.system.boot.loader.initrdFile;
          target = "/boot/" + config.system.boot.loader.initrdFile;
        }
        {
          source = config.boot.kernelPackages.kernel + "/" + config.system.boot.loader.kernelFile;
          target = "/boot/" + config.system.boot.loader.kernelFile;
        }
        {
          source = "${builtins.unsafeDiscardStringContext config.system.build.toplevel}/init";
          target = "/boot/init";
        }
      ];

    };

    system.build.g5k-image-info = pkgs.writeText "g5k-image-info.json" (
      builtins.toJSON {
        kernel = config.boot.kernelPackages.kernel + "/" + config.system.boot.loader.kernelFile;
        initrd = config.system.build.initialRamdisk + "/" + config.system.boot.loader.initrdFile;
        init = "${builtins.unsafeDiscardStringContext config.system.build.toplevel}/init";
        image = "${config.system.build.g5k-image-archive}/tarball/${image_name}.tar.xz";
        kaenv = config.system.build.kadeploy_env_description;
      }
    );

    system.build.g5k-image = pkgs.stdenv.mkDerivation {
      name = "g5k-image";
      dontUnpack = true;
      doCheck = false;

      installPhase = ''
        mkdir $out
        ln -s ${config.system.build.g5k-image-info} $out/g5k-image-info.json
        ln -s ${config.system.build.kadeploy_env_description} $out/${image_name}.yaml
        ln -s ${config.system.build.g5k-image-archive}/tarball/${image_name}.tar.xz $out/${image_name}.tar.xz
      '';
    };


    # TODO: to check
    boot.postBootCommands = ''
      # After booting, register the contents of the Nix store on the
      # CD in the Nix database in the tmpfs.
      if [ -f /nix-path-registration ]; then
      ${config.nix.package.out}/bin/nix-store --load-db < /nix-path-registration &&
      rm /nix-path-registration
      fi

      # nixos-rebuild also requires a "system" profile and an
      # /etc/NIXOS tag.
      touch /etc/NIXOS
      ${config.nix.package.out}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system
    '';

    # To work with initrd.systemd:
    # - 1) add rw to  kernel command line
    #   Extract from /nixos/modules/system/boot/systemd/initrd.nix:
    #  `systemd` mounts root in initrd as read-only unless "rw" is on the kernel command line.
    # - 2) Second: init= must point to NixOS init (in store) 
    # 
    system.build.kadeploy_env_description = pkgs.writeTextFile {
      name = "${image_name}.yaml";
      text = ''
        name: ${image_name}
        version: 1
        description: NixOS
        author: ${author}
        visibility: shared
        destructive: false
        os: linux
        arch: ${arch}
        image:
          file: ${file_image_baseurl}/${image_name}.tar.xz
          kind: tar
          compression: xz
        postinstalls:
        - archive: ${postinstall}
          compression: gzip
          script:  ${postinstall_args}
        boot:
          kernel: /boot/${config.system.boot.loader.kernelFile}
          initrd: /boot/${config.system.boot.loader.initrdFile}
          kernel_params: init=${builtins.unsafeDiscardStringContext config.system.build.toplevel}/init rw console=tty0 console=ttyS0,115200
        filesystem: ext4
        partition_type: 131
        multipart: false
      '';
    };
  };
}
