{
  pkgs ? import <nixpkgs> {},
  system ? builtins.currentSystem,
}: let
  inherit (pkgs) lib;
  sources = builtins.fromJSON (lib.strings.fileContents ./sources.json);

  # Define target version
  # Users can select the version by setting the FOUNDRY_VERSION environment variable
  foundryVersion = builtins.getEnv "FOUNDRY_VERSION";

  # If FOUNDRY_VERSION is not set, default to "stable"
  finalVersion = if foundryVersion != "" then foundryVersion else "stable";

  # Access relevant data from sources.json
  # This handles either "stable", "nightly", or specific version tags
  versionData =
    if builtins.hasAttr finalVersion sources
    then sources.${finalVersion}
    else throw "Foundry version '${finalVersion}' not found in sources.json";

  # Create a base derivation for fetching binary archives and manpages
  mkFoundryBinary = { version, pname, binaryName ? pname }:
    let
      platformData = versionData.platforms.${system};
      manpagesData = versionData.manpages;

      # Create a base derivation for fetching the archive
      foundry-archive = pkgs.fetchurl {
        url = platformData.url;
        sha256 = platformData.sha256;
      };

      # Create a derivation for the manpages
      foundry-manpages = pkgs.fetchurl {
        url = manpagesData.url;
        sha256 = manpagesData.sha256;
      };

      # Create a derivation for unpacking the archive
      foundry-unpacked = pkgs.stdenv.mkDerivation {
        name = "foundry-unpacked-${version}";

        src = foundry-archive;

        # Add autoPatchelfHook for Linux platforms to fix dynamic linking
        nativeBuildInputs = lib.optionals pkgs.stdenv.isLinux [
          pkgs.autoPatchelfHook
        ];

        # Add required runtime dependencies for Linux platforms
        buildInputs = lib.optionals pkgs.stdenv.isLinux [
          pkgs.stdenv.cc.cc.lib  # libstdc++
          pkgs.glibc             # GNU libc compatibility
        ];

        dontBuild = true;
        dontPatch = true;
        dontConfigure = true;

        # Create sourceRoot to handle files at the root level of the archive
        setSourceRoot = "sourceRoot=`pwd`";

        installPhase = ''
          mkdir -p $out/bin

          # Copy the binaries directly from the archive root
          cp forge cast anvil chisel $out/bin/

          # Make sure they're executable
          chmod +x $out/bin/*

          # Extract manpages directly to the man1 directory
          mkdir -p $out/share/man/man1
          ${pkgs.gnutar}/bin/tar -xzf ${foundry-manpages} -C $out/share/man/man1 || true
        '';

        meta = {
          description = "Foundry toolchain binaries for Ethereum development";
          homepage = "https://github.com/foundry-rs/foundry";
          license = pkgs.lib.licenses.mit;
          platforms = pkgs.lib.platforms.unix;
        };
      };
    in
      pkgs.stdenv.mkDerivation {
        inherit version;
        pname = pname;

        src = foundry-unpacked;

        # These might not be needed here since the binaries are already patched in foundry-unpacked,
        # but including them for completeness and to ensure the runtime dependencies are propagated
        nativeBuildInputs = lib.optionals pkgs.stdenv.isLinux [
          pkgs.autoPatchelfHook
        ];

        buildInputs = lib.optionals pkgs.stdenv.isLinux [
          pkgs.stdenv.cc.cc.lib
          pkgs.glibc
        ];

        dontBuild = true;
        dontPatch = true;
        dontConfigure = true;

        installPhase = ''
          mkdir -p $out/bin
          cp $src/bin/${binaryName} $out/bin/

          # Copy man pages if they exist (they're compressed with .gz extension)
          if [ -f $src/share/man/man1/${binaryName}.1.gz ]; then
            mkdir -p $out/share/man/man1
            cp $src/share/man/man1/${binaryName}.1.gz $out/share/man/man1/
          fi
        '';

        meta = {
          description = "Foundry ${pname} - Ethereum development tool";
          homepage = "https://github.com/foundry-rs/foundry";
          license = pkgs.lib.licenses.mit;
          platforms = pkgs.lib.platforms.unix;
        };
      };

  # Create individual package derivations
  forge = mkFoundryBinary {
    version = versionData.version;
    pname = "forge";
  };

  cast = mkFoundryBinary {
    version = versionData.version;
    pname = "cast";
  };

  anvil = mkFoundryBinary {
    version = versionData.version;
    pname = "anvil";
  };

  chisel = mkFoundryBinary {
    version = versionData.version;
    pname = "chisel";
  };

  # Convenience all-in-one package
  foundry = pkgs.symlinkJoin {
    name = "foundry-${versionData.version}";
    paths = [ forge cast anvil chisel ];
    meta = {
      description = "Complete Foundry toolchain for Ethereum development";
      homepage = "https://github.com/foundry-rs/foundry";
      license = pkgs.lib.licenses.mit;
      platforms = pkgs.lib.platforms.unix;
    };
  };

in {
  inherit forge cast anvil chisel foundry;
  default = foundry;
}
