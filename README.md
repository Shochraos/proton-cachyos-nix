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

## Credit

This package simply provides a Nix flake for the excellent work done by the CachyOS team on their Proton fork (https://github.com/CachyOS/proton-cachyos). All credit for Proton-CachyOS itself goes to them. And credit to Valve for their work on Proton (https://github.com/ValveSoftware/Proton).
