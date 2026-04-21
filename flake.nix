{
  description = "NixOS G5K Images";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    kapack.url = "gitlab:kairns/kapack?host=gricad-gitlab.univ-grenoble-alpes.fr";
    kapack.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs =
    { self
    , nixpkgs
    , kapack
    , ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ (_: _: kapack.packages.${system}) ];
      };
      lib = pkgs.lib;
    in
    {
      nixosModules = {
        g5k-image = import ./modules/g5k-image.nix;
      };

      templates = {
        minimal = {
          description = "Minimal Nixos Grid'5000 image, tarball file with enviroment description";
          path = ./templates/minimal;
        };
        user = {
          description = "Nixos Grid'5000 image with user support and helper (ssh, nfs home)";
          path = ./templates/user;
        };
        kapack = {
          description = "Nixos Grid'5000 image, based on user version with addition of kapack's pkgs and modules";
          path = ./templates/kapack;
        };
        defaultTemplate = self.templates.user;
      };

      formatter.${system} = pkgs.writeShellScriptBin "formatter" ''
        set -eoux pipefail
        shopt -s globstar
        ${lib.getExe pkgs.deno} fmt README.md
        ${lib.getExe pkgs.nixpkgs-fmt} .
        ${lib.getExe pkgs.just} --fmt --unstable
      '';
    };
}
