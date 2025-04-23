# Foundry Nix Flake Overlay

This repository provides a Nix flake overlay for [Foundry](https://github.com/foundry-rs/foundry), a blazing fast, portable, and modular toolkit for Ethereum application development written in Rust. The flake packages the pre-built binary releases from the official Foundry repository, removing the need for a Rust toolchain to use Foundry.

## Features

- Packages all official Foundry tools: `forge`, `cast`, `anvil`, and `chisel`
- Downloads pre-built binaries directly from official releases
- Includes man pages for all tools
- Works on multiple platforms: Linux (x86_64) and macOS (Intel/Apple Silicon)
- Properly handles dynamic linking on NixOS and other Linux distributions
- Provides a convenient development shell with all tools pre-configured

## Usage

### As a Flake (Recommended)

In your `flake.nix` file:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    foundry.url = "github:foundry-rs/foundry";
  };

  outputs = { self, nixpkgs, foundry, ... }:
    let
      system = "x86_64-linux"; # or x86_64-darwin, aarch64-darwin
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ foundry.overlays.default ];
      };
    in {
      # Use foundry in your packages
      packages.default = pkgs.mkShell {
        buildInputs = [
          pkgs.foundry # All tools in one package
          # Or individual tools
          # pkgs.forge
          # pkgs.cast
          # pkgs.anvil
          # pkgs.chisel
        ];
      };
    };
}
```

### Command Line Usage

```sh
# Install and run forge (latest stable version)
$ nix run github:0xbigboss/foundry-overlay#forge

# Open a shell with all Foundry tools available
$ nix develop github:0xbigboss/foundry-overlay

# Build a specific tool
$ nix build github:0xbigboss/foundry-overlay#anvil

# Use a specific tool within your shell
$ nix shell github:0xbigboss/foundry-overlay#cast
```

### Non-Flake Usage (Legacy Nix)

If you're not using flakes, you can still use this package through the `default.nix` compatibility layer:

```nix
let
  foundryOverlay = import (fetchTarball "https://github.com/0xbigboss/foundry-overlay/archive/main.tar.gz");
  pkgs = import <nixpkgs> { overlays = [ foundryOverlay ]; };
in pkgs.mkShell {
  buildInputs = [ pkgs.foundry ];
}
```

## Available Packages and Outputs

The flake provides the following outputs:

- `packages.<system>.forge`: The Forge testing framework
- `packages.<system>.cast`: The Cast command-line tool for interacting with EVM smart contracts
- `packages.<system>.anvil`: The Anvil local testnet node
- `packages.<system>.chisel`: The Chisel Solidity REPL
- `packages.<system>.foundry`: A combined package containing all tools
- `packages.<system>.default`: Same as `foundry`

- `apps.<system>.forge`: Run the `forge` command
- `apps.<system>.cast`: Run the `cast` command
- `apps.<system>.anvil`: Run the `anvil` command
- `apps.<system>.chisel`: Run the `chisel` command
- `apps.<system>.default`: Run the `forge` command

- `devShells.<system>.default`: A development shell with all Foundry tools

- `overlays.default`: An overlay that adds Foundry packages to nixpkgs

## Templates

This flake provides the following templates:

### Foundry Template

A basic Foundry project template for Ethereum development:

```sh
# Create a new project using the Foundry template
$ mkdir my-foundry-project
$ cd my-foundry-project
$ nix flake init -t github:0xbigboss/foundry-overlay#init
```

The template includes:
- Nix configuration with all Foundry tools available
- Direnv integration for automatic environment loading

After initializing the template:

```sh
# Enter the development environment
$ nix develop

# Build and test the sample contract
$ forge init . --force
$ forge build
$ forge test
```

## Updating to New Versions

You can update to new Foundry versions in two ways:

### 1. Using the Update Script

The included `update` script automates the process of updating `sources.json` for new Foundry releases:

```sh
# Update to the latest stable release
$ ./update
# Or update to the latest nightly release
$ ./update nightly
```

The script will:
- Fetch the latest release information from GitHub
- Download each platform's binary archive
- Verify the attestations of the downloaded binaries using GitHub's attestation verification system
- Generate SHA256 hashes for the verified archives
- Download and verify the manpages archive
- Update `sources.json` with the new URLs and hashes
- Preserve any existing entries for different versions

#### Attestation Verification

By default, the update script now verifies the authenticity of Foundry binaries using GitHub's attestation system. This ensures that the binaries you're using were actually built by the official Foundry GitHub Actions workflow.

If you need to skip verification (e.g., for older releases that might not have attestations):

```sh
# Skip attestation verification
$ SKIP_VERIFICATION=true ./update
```

This security feature helps protect against supply chain attacks by ensuring that the binaries haven't been tampered with.

### 2. Manual Updates

To manually update the flake:

1. Update the SHA256 hashes in `sources.json` for each platform and the manpages
2. Update the version information if needed

## Version Selection

This flake supports multiple Foundry versions:

### Stable Releases

By default, the flake uses the "stable" release. This is the recommended version for most users.

### Nightly Builds

The flake also supports "nightly" builds. To use the nightly version, you need to:

1. Add the nightly release to `sources.json` (using `./update nightly`)
2. Specify the nightly version when using the flake:

```sh
# Using environment variable
$ FOUNDRY_VERSION=nightly nix develop
$ FOUNDRY_VERSION=nightly nix run .#forge

# Or when importing in another flake
foundryVersion = "nightly";
```

### Specific Versions

You can pin to specific versions by adding them to `sources.json` and then selecting them via the environment variable:

```sh
$ FOUNDRY_VERSION=v0.2.0 nix develop
```

## Development

### Testing the Flake

To test that the flake is working correctly:

```sh
# Check the flake structure
$ nix flake check

# Build individual packages
$ nix build .#forge
$ nix build .#cast
$ nix build .#anvil
$ nix build .#chisel

# Build the combined package
$ nix build .#foundry

# Test the binaries
$ ./result/bin/forge --version

# Test the development shell
$ nix develop
$ forge --version
```

### Platform Compatibility

The flake is designed to work on all supported platforms:

- **Linux (x86_64)**: Includes proper dynamic linking support for NixOS and other Linux distributions using `autoPatchelfHook` and required runtime dependencies.
- **macOS (Intel/Apple Silicon)**: Works with native macOS binaries without additional dependencies.

If you encounter any platform-specific issues, please report them in the GitHub issues.

## License

This flake is released under the MIT License. Foundry itself is developed by [foundry-rs](https://github.com/foundry-rs/foundry) and is also released under the MIT License.
