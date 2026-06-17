{
  description = "Default NixOS image for Grid'5000 Testbed";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-g5k-image = {
      url = "github:oar-team/nixos-g5k-image";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , nixos-g5k-image
    , ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };
      lib = pkgs.lib;

      nixosConfig = nixpkgs.lib.nixosSystem {
        inherit system;

        modules = [
          nixos-g5k-image.nixosModules.g5k-nfs-store
          ./configuration.nix
        ];
      };
    in

    {
      packages.${system} = rec {
        #g5k-nfs-store-info = nixosConfig.config.system.build.g5k-nfs-store-info;
        g5k-nfs-store = nixosConfig.config.system.build.toplevel;
        default = g5k-nfs-store;
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
