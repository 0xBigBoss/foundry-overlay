{
  description = "Foundry binaries for Ethereum development.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";

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
    ...
  }: let
    systems = ["x86_64-linux" "x86_64-darwin" "aarch64-darwin"];
    outputs = flake-utils.lib.eachSystem systems (system: let
      pkgs = nixpkgs.legacyPackages.${system};

      # Import packages from default.nix
      foundryPkgs = import ./default.nix { inherit pkgs system; };
    in rec {
      # The packages exported by the Flake
      packages = foundryPkgs;

      # "Apps" so that `nix run` works
      apps = {
        forge = flake-utils.lib.mkApp {
          drv = packages.forge;
          name = "forge";
        };
        cast = flake-utils.lib.mkApp {
          drv = packages.cast;
          name = "cast";
        };
        anvil = flake-utils.lib.mkApp {
          drv = packages.anvil;
          name = "anvil";
        };
        chisel = flake-utils.lib.mkApp {
          drv = packages.chisel;
          name = "chisel";
        };
        default = apps.forge;
      };

      # nix fmt
      formatter = pkgs.alejandra;

      # Development shell with foundry tools
      devShells.default = pkgs.mkShell {
        nativeBuildInputs = [
          packages.forge
          packages.cast
          packages.anvil
          packages.chisel
        ];
      };

      # For compatibility with older versions of the `nix` binary
      devShell = self.devShells.${system}.default;
    });
  in
    outputs
    // {
      # Overlay that can be imported so you can access the packages
      overlays.default = final: prev: {
        foundryPackages = outputs.packages.${prev.system};
        forge = outputs.packages.${prev.system}.forge;
        cast = outputs.packages.${prev.system}.cast;
        anvil = outputs.packages.${prev.system}.anvil;
        chisel = outputs.packages.${prev.system}.chisel;
        foundry = outputs.packages.${prev.system}.foundry;
      };

      templates.init = {
        path = ./templates/init;
        description = "A basic empty Foundry development environment.";
      };
    };
}
