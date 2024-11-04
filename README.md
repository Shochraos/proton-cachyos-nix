# Nix Proton CachyOS

A Nix flake for [CachyOS Proton](https://github.com/CachyOS/proton-cachyos), a compatibility tool for Steam Play based on Wine with additional patches and optimizations from CachyOS.

> **Disclaimer**: This is an unofficial, community-maintained Nix package. It is not affiliated with, officially connected to, or endorsed by Valve Corporation, CachyOS, or any of their subsidiaries or affiliates. The names Proton, CachyOS, and any related names are trademarks of their respective owners.

## Usage

Add to your NixOS configuration:

```nix
{
  inputs = {
    # Your other inputs...
    nix-proton-cachyos.url = "github:kimjongbing/nix-proton-cachyos";
  };
}
```

Then add it to your Steam configuration:

```nix
# In your Steam configuration (e.g., configuration.nix or steam.nix)
programs.steam = {
  enable = true;
  extraCompatPackages = [
    inputs.nix-proton-cachyos.packages.${system}.proton-cachyos
  ];
};
```

After rebuilding your system, you should see something like "Proton-CachyOS" in Steam's compatibility tools list (Steam -> Settings -> Compatibility).

## Updates

This package automatically checks for updates every 6 hours and creates a pull request when a new version is available on the CachyOS mirror. To get the latest version:

1. Update your flake inputs:
```bash
nix flake update nix-proton-cachyos
```

2. Rebuild your system:
```bash
sudo nixos-rebuild switch
```

## Contributing

This is a community-maintained package and help is welcome! If you'd like to contribute:

1. Issues: 
   - Report packaging issues (e.g., installation problems, Steam not detecting the tool)
   - Problems with the Nix flake itself
   - Note: For issues with games or Proton itself, please report to:
     - [CachyOS Proton](https://github.com/CachyOS/proton-cachyos) for CachyOS-specific issues
     - [Valve Proton](https://github.com/ValveSoftware/Proton) for general Proton issues

2. Pull Requests: 
   - Improvements to the Nix packaging
   - Documentation updates
   - Automation enhancements

3. Documentation:
   - Help improve installation instructions
   - Add usage examples
   - Clarify system requirements

This repository only handles the Nix packaging of Proton-CachyOS. We can't fix issues with the underlying Proton implementation.

## Credits

This package is just a Nix flake wrapper around:

- [Proton-CachyOS](https://github.com/CachyOS/proton-cachyos) by the CachyOS team - a fork of Proton with additional optimizations
- [Proton](https://github.com/ValveSoftware/Proton) by Valve Corporation - the original compatibility layer for Steam Play

All credit for the underlying software goes to their respective teams. This repository simply provides the Nix packaging to make it easier to use on NixOS.
