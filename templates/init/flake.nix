{
  description = "A basic Foundry project template for Ethereum development.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
    foundry-overlay.url = "github:0xbigboss/foundry-overlay";

    # Used for shell.nix
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    foundry-overlay,
    ...
  } @ inputs: let
    overlays = [
      foundry-overlay.overlays.default
    ];

    # Our supported systems are the same as foundry-overlay
    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
  in
    flake-utils.lib.eachSystem systems (
      system: let
        pkgs = import nixpkgs {inherit overlays system;};
      in rec {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            # Foundry tools
            forge
            cast
            anvil
            chisel
          ];
        };

        # For compatibility with older versions of the `nix` binary
        devShell = self.devShells.${system}.default;
      }
    );
}
