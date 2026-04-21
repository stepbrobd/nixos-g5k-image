{ pkgs, ... }:
let
  user = import ./user.nix;
in
{
  environment.systemPackages = with pkgs; [
    vim
    just
    jq
    nushell
    tmux
    nxc # from Kapack
  ];

  # not really useful service from Kapack
  services.my-startup.enable = true;

  virtualisation = {
    docker = {
      enable = true;
    };
  };
  fileSystems = {
    "/home/${user.name}" = {
      device = "nfs:/export/home/${user.name}";
      fsType = "nfs";
    };
  };

  nix.settings.trusted-users = [ user.name ];
  users.groups.g5k-users.gid = 8000;
  users.users."${user.name}" = {
    isNormalUser = true;
    uid = user.uid;
    group = "g5k-users";
    extraGroups = [
      "wheel"
      "adm"
      "dialout"
      "docker"
    ];
    openssh.authorizedKeys.keys = [ user.id_rsa_pub ];
  };
}
