{
  description = "Proton CachyOS build";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      protonCachyosVersions = builtins.fromJSON (builtins.readFile ./versions.json);
    in {
      packages.${system} = {
        proton-cachyos = pkgs.callPackage ./default.nix {
          inherit protonCachyosVersions;
        };
        proton-cachyos-v3 = pkgs.callPackage ./default.nix {
          inherit protonCachyosVersions;
          microArchitecture = "x86_64_v3";
        };
        default = self.packages.${system}.proton-cachyos;
      };
    };
}
