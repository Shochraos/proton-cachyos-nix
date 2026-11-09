{
  description = "CachyOS Proton and DW-Proton binary packages";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      protonCachyosVersions = builtins.fromJSON (builtins.readFile ./proton-cachyos/versions.json);
      dwProtonVersions = builtins.fromJSON (builtins.readFile ./dw-proton/versions.json);
    in
    {
      packages.${system} = {
        proton-cachyos = pkgs.callPackage ./proton-cachyos/proton-cachyos.nix {
          inherit protonCachyosVersions;
        };
        proton-cachyos-v3 = pkgs.callPackage ./proton-cachyos/proton-cachyos.nix {
          inherit protonCachyosVersions;
          microArchitecture = "x86_64_v3";
        };
        dw-proton = pkgs.callPackage ./dw-proton/dw-proton.nix {
          inherit dwProtonVersions;
        };
        default = self.packages.${system}.proton-cachyos;
      };
    };
}
