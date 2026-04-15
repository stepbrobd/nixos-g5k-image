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
    {
      self,
      nixpkgs,
      nixos-g5k-image,
      ...
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
          nixos-g5k-image.nixosModules.g5k-image
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
