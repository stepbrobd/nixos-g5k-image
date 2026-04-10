{ pkgs, ... }:
{
  # add vim editor
  environment.systemPackages = with pkgs; [
    vim
    just
    jq
    nushell
    tmux
  ];

  virtualisation = {
    #    virtualbox.host.enable = true;
    #    #virtualbox.host.enableExtensionPack = true;
    docker = {
      enable = true;

    };
  };
  fileSystems = {
    "/home/orichard" = {
      device = "nfs:/export/home/orichard";
      fsType = "nfs";
    };
  };

  nix.settings.trusted-users = [ "orichard" ];
  users.groups.g5k-users.gid = 8000;
  users.users.orichard = {
    #description = "Olivier Richard on G5K";
    isNormalUser = true;
    uid = 15002; # (id -u # on G5K
    group = "g5k-users";
    extraGroups = [
      "wheel"
      "adm"
      "dialout"
      "docker"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDdQ3fxwPR0TCISMMTUjNdyohPxUW/DOErWq3uBDP1Rt3xQY8lrFAQwsOR0dHh/IbhFNi2VlVp3l6W63srrODBwyGHbWVNReG9f5OZXg3pFf/OFOzpYmi592K8Laa9EgmLpoD6mgaO0ma6xW5ipzvDO2fIfykUACPFI0PPX05MfHnsu0h/3htszucXGZNRE9NN7M4sB80Qxw8z6JfWbEhEo0tnroEuNZ3oGd0dDZ+FvScI3kz/m3M3qZVp7jGqoORxSXYmvUUpf289e3qKN8oOp17p+zuI3VxR7iO9h9dLoBdWgkHs513A8pXVknbrp6XUI0hT/EDSmujPk4gWjAcwx Generated passwordless ssh key to move between sites and connect nodes"
    ];
  };
}
