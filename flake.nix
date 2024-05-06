{
  description = "Description for the project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, nixpkgs, crane, rust-overlay, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
      ];
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }:
        let
          pkgs = nixpkgs.legacyPackages.${system}.appendOverlays ([ rust-overlay.overlays.default ]);

          inherit (pkgs) lib;

          rustToolchain = pkgs.rust-bin.selectLatestNightlyWith (toolchain: toolchain.default.override {
            extensions = [ "rust-src" "rust-analyzer" ];
          });
          craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;
        in
        {
          packages = rec {
            host = craneLib.buildPackage {
              src = craneLib.cleanCargoSource (craneLib.path ./.);
            };
            module = craneLib.buildPackage {
              src = craneLib.cleanCargoSource (craneLib.path ./.);
              cargoExtraArgs = "-p dylib";
            };
            # Per-system attributes can be defined here. The self' and inputs'
            # module parameters provide easy access to attributes of the same
            # system.

            default = pkgs.writeShellApplication {
              name = "run-with-loaded-libary";
              text = ''
                RUST_LOG=debug ${lib.getExe host} ${module}/lib/libdylib.so
              '';
            };
          };

          devShells.default = pkgs.makeShell {
            name = "devshell";
            buildInputs = [ rustToolchain ];
            RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
          };
        };
      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.

      };
    };
}
