{
  pkgs,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    "${modulesPath}/profiles/all-hardware.nix"
    "${modulesPath}/profiles/base.nix"
    "${modulesPath}/installer/scan/detected.nix"
    "${modulesPath}/installer/scan/not-detected.nix"
  ];

  options = { };
  config = {
    # FIXME: migration to systemd stage 1 required soon!
    # https://gitlab.inria.fr/nixos-compose/nixos-compose/-/issues/63
    boot.initrd.systemd.enable = lib.mkForce false;
    networking.useDHCP = true;

    # Hostname sets below, retrieved w/ nslookup and set in /etc/hostname
    networking.hostName = lib.mkForce "";

    boot.initrd.extraUtilsCommands = ''
      cp -pv ${pkgs.glibc}/lib/libnss_files.so.2 $out/lib
      cp -pv ${pkgs.glibc}/lib/libresolv.so.2 $out/lib
      cp -pv ${pkgs.glibc}/lib/libnss_dns.so.2 $out/lib
    '';

    boot.initrd.postMountCommands = ''
      allowShell=1
      #set -xv
      #echo Breakpoint reached && fail

      for o in $(cat /proc/cmdline); do
          case $o in
             nfs_store=*)
               set -- $(IFS==; echo $o)
               nfs_store="$2"
               echo "nfs_store: $nfs_store"
               ;;
        esac
      done

      if [ "''${nfs_store+set}" = set ]; then
          mkdir -p /mnt-root/nix/.server-ro-store
          mkdir -p /mnt-root/nix/.rw-store/work
          mkdir -p /mnt-root/nix/.rw-store/store
          mkdir -p /mnt-root/nix/store

          # If not use busybox's mount
          if [ ! -L "/bin/mount" ]; then
              echo "WARNING: replace mount command by link to busybox"
              rm /bin/mount
              ln -s /bin/busybox /bin/mount
          fi

          echo "Mount NFS store: $nfs_store"
          mount -t nfs -o vers=3,nolock,ro,soft,retry=10 $nfs_store /mnt-root/nix/.server-ro-store
          mount -t overlay overlay -o lowerdir=/mnt-root/nix/.server-ro-store,upperdir=/mnt-root/nix/.rw-store/store,workdir=/mnt-root/nix/.rw-store/work /mnt-root/nix/store
      else
          echo "nfs_store in kernel's parameters is missing, it's require for g5k_nfs_store" && fail
      fi

      # Retrieve and set hostname
      set -- $(IFS=' '; echo $(ip route get 1.0.0.0))
      ip_addr=$7
      hostname=$(nslookup $ip_addr | sed -n 's/.*name = //p' | sed 's/\..*//')
      echo "Hostname: $hostname"
      mkdir -p /mnt-root/etc
      echo $hostname > /mnt-root/etc/hostname
      #echo Breakpoint reached && fail
    '';

    services.sshd.enable = true;

    services.getty.autologinUser = lib.mkDefault "root";

    security.polkit.enable = false; # to reduce initrd
    services.udisks2.enable = false; # to reduce initrd

    boot.initrd.availableKernelModules = [
      "ahci"
      "ehci_pci"
      "megaraid_sas"
      "sd_mod"
      "i40e"
      "mlx5_core"
    ];

    boot.kernelModules = lib.optionals pkgs.stdenv.hostPlatform.isx86 [ "kvm-intel" "kvm-amd" ];

    # Kadeploy tests some ports' accessibility to follow deployment steps
    networking.firewall.enable = false;
    boot.supportedFilesystems = [ "nfs" ];

    boot.loader.grub.enable = lib.mkDefault false;

    fileSystems."/" = {
      fsType = "tmpfs";
      options = [ "mode=0755" ];
    };

    boot.initrd.network.enable = true;
    boot.initrd.kernelModules = [
      "squashfs"
      "loop"
      "overlay"
      "nfsv3"
      "igb"
      "ixgbe"
    ];

    # Required for nfs mount to work in the early of stage-2
    boot.initrd.network.flushBeforeStage2 = false;
    system.stateVersion = lib.mkDefault lib.trivial.release;
  };
}
