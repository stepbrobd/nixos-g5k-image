{
  description = "Default NixOS image for Grid'5000 Testbed";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-g5k-image = {
      url = "github:oar-team/nixos-g5k-image";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    kapack.url = "gitlab:kairns/kapack?host=gricad-gitlab.univ-grenoble-alpes.fr";
    kapack.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { self
    , nixpkgs
    , nixos-g5k-image
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

      nixosConfig = nixpkgs.lib.nixosSystem {
        inherit system pkgs;
        modules = [
          nixos-g5k-image.nixosModules.g5k-image
          kapack.nixosModules.my-startup
          (import ./configuration.nix)
        ];
      };
    in

    {
      packages.${system} = rec {
        g5k-image = nixosConfig.config.system.build.g5k-image;
        default = g5k-image;
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
