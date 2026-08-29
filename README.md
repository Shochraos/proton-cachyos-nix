# Nix Proton-CachyOS

Nix packaging for [Proton-CachyOS](https://github.com/CachyOS/proton-cachyos), CachyOS's Proton build with additional patches and optimizations, as a Steam Play compatibility tool.

> **AI disclaimer:** The Nix packaging and this README are maintained with AI assistance. The package installs a binary tarball published on the upstream release page. Read what you install.

## How it works

- `versions.json` pins the build (`base`, `release`, and a sha512 hash per microarchitecture). `flake.nix` reads it with `builtins.fromJSON`, and `default.nix` fetches the matching `proton-cachyos-<base>-<release>-slr-<arch>` tarball from the upstream release page with that hash. Only `x86_64-linux` is built.
- Two attributes share one derivation: `proton-cachyos` for the baseline `x86_64` build and `proton-cachyos-v3` for the `x86_64_v3` one. Both rewrite `compatibilitytool.vdf` so the tool registers under the same internal name, `proton-cachyos-slr`, with the display name `Proton-CachyOS-<base>-<release>-<arch>` carrying the microarchitecture, and install it to `share/steam/compatibilitytools.d/proton-cachyos-slr`. The shared internal name means Steam keeps per-game tool selections when you switch between the two.
- The tarball ships a `.update-timestamp` marker inside its default prefix, and Proton stamps new prefixes with the mtime of the distribution's `wine.inf`. Wine re-runs its wine.inf prefix update whenever a prefix's marker disagrees with the live `wine.inf` mtime. The marker the tarball carries records the mtime from the machine that built the tarball, which the Nix store does not reproduce. The build therefore deletes the shipped marker and points Proton's stamp write at `/dev/null`. Wine seeds the timestamp itself on a prefix's first launch, and the check compares equal from then on.

Packaging problems belong here. Game and Proton issues go upstream: to [Proton-CachyOS](https://github.com/CachyOS/proton-cachyos) and the [CachyOS wiki](https://wiki.cachyos.org/) for CachyOS-specific problems, to [Valve's Proton](https://github.com/ValveSoftware/Proton) for general ones.

## Usage

Add the input:

```nix
{
  inputs.nix-proton-cachyos = {
    url = "github:Shochraos/nix-proton-cachyos";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

Then add it to Steam:

```nix
{ inputs, pkgs, ... }:
{
  programs.steam = {
    enable = true;
    extraCompatPackages = [
      inputs.nix-proton-cachyos.packages.${pkgs.stdenv.hostPlatform.system}.proton-cachyos
    ];
  };
}
```

`proton-cachyos` is also the flake's `default` package. After the rebuild, `Proton-CachyOS-<base>-<release>-<arch>` (currently `Proton-CachyOS-11.0-20260703-x86_64`) appears in Steam's compatibility tools list (Steam → Settings → Compatibility).

### x86-64-v3 build

CachyOS publishes a second build of every release, compiled for the `x86-64-v3` microarchitecture level (AVX2, BMI2, FMA — Intel Haswell / AMD Excavator and newer). Select it with the `proton-cachyos-v3` attribute:

```nix
extraCompatPackages = [
  inputs.nix-proton-cachyos.packages.${pkgs.stdenv.hostPlatform.system}.proton-cachyos-v3
];
```

Both attributes install under the same internal tool name, so only one of them can be in `extraCompatPackages` at a time; the two collide. The display name shown in the Steam UI carries the microarchitecture, so you can tell which one is active.

Check that your CPU supports the level before switching:

```bash
/lib64/ld-linux-x86-64.so.2 --help | grep x86-64-v3
```

## Updates

Every day at 00:00 UTC (and on manual dispatch), the update workflow reads the latest upstream release tag, verifies it matches `cachyos-<base>-<release>-slr`, and fetches the `.sha512sum` files CachyOS publishes next to the tarballs, converting each to SRI form for `versions.json`. A missing or malformed checksum fails the run. If nothing changed, nothing is committed; otherwise the new pin goes straight to `main` and CI builds both packages on the next push. To pick up a new version:

```bash
nix flake update nix-proton-cachyos
sudo nixos-rebuild switch
```

## Development

`nix build .#proton-cachyos` and `nix build .#proton-cachyos-v3` build the pinned releases and `nix flake check` evaluates the flake. Pushes and PRs to `main` run a CI matrix over both packages: the build step checks that `compatibilitytool.vdf` and an executable `proton` land in the installed tool directory, that the vdf names `proton-cachyos-slr` as the tool and carries the `Proton-CachyOS-` display name, and that no `.update-timestamp` survives in the default prefix. nixpkgs is pinned to `nixpkgs-unstable`.

## License

The [LICENSE](LICENSE) file documents the license the packaged software ships under: Valve's BSD-style license for Proton. The repository itself is Nix packaging only.
