# Proton packages for Nix

## Summary

Nix packages for [Proton-CachyOS](https://github.com/CachyOS/proton-cachyos) and [DW-Proton](https://dawn.wine/dawn-winery/dwproton), for Steam on `x86_64-linux`.

The packaging, update automation, and documentation are maintained with AI assistance. Packages install prebuilt upstream release archives; this repository does not compile Proton from source. Read what you install.

## Installation

Add one input to your NixOS flake, following your existing nixpkgs input:

```nix
{
  inputs.proton = {
    url = "github:Shochraos/proton-cachyos-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

Select packages in your NixOS configuration:

```nix
{ inputs, pkgs, ... }:
{
  programs.steam = {
    enable = true;
    extraCompatPackages = [
      inputs.proton.packages.${pkgs.stdenv.hostPlatform.system}.proton-cachyos
      inputs.proton.packages.${pkgs.stdenv.hostPlatform.system}.dw-proton
    ];
  };
}
```

Rebuild your configuration, restart Steam, and select a tool in the game's Properties → Compatibility settings. Steam integration and game compatibility depend on your system and upstream release.

## Usage

- `proton-cachyos`: baseline `x86_64` build and the flake's `default` package.
- `proton-cachyos-v3`: `x86_64_v3` build; requires a CPU supporting the full x86-64-v3 feature set, including AVX2, BMI2, and FMA. Confirm support before selecting it.
- `dw-proton`: Dawn Winery's Proton build.

Use only one CachyOS variant at a time: both install as `proton-cachyos-slr` and share the same Steam identity. Replace the baseline attribute with `proton-cachyos-v3` to switch. The display name, `Proton-CachyOS-<base>-<release>-<arch>`, identifies the selected variant. DW uses the versioned identity `DW-Proton-<base>-<release>` and installs separately as `dw-proton`.

When migrating from `Shochraos/dw-proton-nix`, select this input's `dw-proton` explicitly: this repository's default is CachyOS, not DW. Remove the separate DW input only after replacing its references, and update only the affected consumer lock inputs. Direct recipe imports must use `proton-cachyos/proton-cachyos.nix` or `dw-proton/dw-proton.nix` with their existing version arguments; the former root recipe and version paths are not retained.

Report packaging issues here; report game or Proton issues to the relevant [CachyOS](https://github.com/CachyOS/proton-cachyos), [Dawn Winery](https://dawn.wine/dawn-winery/dwproton), or [Valve](https://github.com/ValveSoftware/Proton) upstream.

## Architecture

One flake exposes separate provider recipes and pinned upstream binary archives, with one shared nixpkgs lock. Each recipe preserves its provider's archive layout and Steam identity. Both remove shipped prefix timestamp markers and redirect Proton's timestamp write to `/dev/null` for the Nix store.

Package CI builds all three named packages and inspects their installed files without running Proton. A serialized updater validates each provider's candidate, builds the affected packages, and checks their artifacts before publishing accepted pins. These checks do not establish Steam or game compatibility.

## License

Only original contributions to this repository whose copyright is held by Shochraos are dedicated to the public domain under the [Unlicense](UNLICENSE). Inherited packaging, contributions by others, and downloaded Proton-CachyOS/DW-Proton software and bundled components are excluded; their original applicable terms and notices remain in effect.

[LICENSE](LICENSE) explains the scope and retains Valve's Proton notice, which is not a complete license inventory for the distributions. The packaging retains its origin as a fork of [kimjongbing/nix-proton-cachyos](https://github.com/kimjongbing/nix-proton-cachyos).
