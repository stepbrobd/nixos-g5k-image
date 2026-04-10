{
  description = "nixos-g5k-image generator";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.11";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    kapack.url = "gitlab:kairns/kapack?host=gricad-gitlab.univ-grenoble-alpes.fr";
    kapack.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs =
    {
      nixpkgs,
      kapack,
      nixos-generators,
      ...
    }:
    let
      system = "x86_64-linux";
      #nixpkgs.overlays = [ (_: _: kapack.packages.${system}) ];
      #pkgs = nixpkgs.legacyPackages.${system};
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ (_: _: kapack.packages.${system}) ];
      };
    in
    {
      packages.x86_64-linux = {
        kexec = nixos-generators.nixosGenerate {
          system = "x86_64-linux";
          modules = [
            ./configuration.nix
          ];
          format = "kexec";
        };
        g5k-image = nixos-generators.nixosGenerate {
          system = "x86_64-linux";
          modules = [
            # UGLY: TODO: Remove use of nixos-generators
            (
              { ... }:
              {
                environment.systemPackages = [ pkgs.nxc ];
              }
            )
            ./configuration.nix
          ];
          customFormats = {
            "g5k-image" = ./format/g5k-image.nix;
          };
          format = "g5k-image";
        };
      };
    };
}
