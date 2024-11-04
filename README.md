# Nix Proton CachyOS

A Nix flake for [CachyOS Proton](https://github.com/CachyOS/proton-cachyos), a compatibility tool for Steam Play based on Wine with additional patches and optimizations from CachyOS.

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

After rebuilding your system, you should see "Proton-CachyOS" in Steam's compatibility tools list (Steam -> Settings -> Compatibility).

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

This is a community-maintained package and help is very welcome! If you'd like to contribute:

1. Issues: Report any problems or suggest improvements by opening an issue
2. Pull Requests: Feel free to submit improvements to the packaging
3. Testing: Test the package with different games and report any issues
4. Documentation: Help improve these docs or add usage examples

## Credits

This package is just a Nix flake wrapper around:

- [Proton-CachyOS](https://github.com/CachyOS/proton-cachyos) by the CachyOS team - a fork of Proton with additional optimizations
- [Proton](https://github.com/ValveSoftware/Proton) by Valve Corporation - the original compatibility layer for Steam Play

All credit for the underlying software goes to their respective teams. This repository simply provides the Nix packaging to make it easier to use on NixOS.
