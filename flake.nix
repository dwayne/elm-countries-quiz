{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-utils-src = { url = "github:dwayne/nix-utils"; flake = false; };
    flake-elm2nix = {
      url = "github:dwayne/elm2nix/use-elm-0.19.3";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nix-utils-src.follows = "nix-utils-src";
      };
    };
    flake-nix-elm-parcel = {
      url = "github:dwayne/nix-elm-parcel";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nix-utils-src.follows = "nix-utils-src";
        flake-elm2nix.follows = "flake-elm2nix";
      };
    };
  };

  outputs = { self, nixpkgs, nix-utils-src, flake-elm2nix, flake-nix-elm-parcel }:
    let
      lib = nixpkgs.lib;
      nixUtils = import nix-utils-src lib;
    in
    nixUtils.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ flake-nix-elm-parcel.overlays.default ];
        };
      in
      pkgs.nixElmParcelPackages.defaultFlakeOutput {
        name = "elm-countries-quiz";
        root = ./.;
        hash = "sha256-i9XiaMPLrVzQt68mn+y3ZejsJ2HGzObRtHcP/zPtuc0=";

        extraPaths = [ ".postcssrc" "tailwind.config.js" ];
        patches = flake-elm2nix.lib.elmSafeVirtualDomPatches.default;

        deployBranch = "gh-pages";

        devShellArgs = {
          env = {
            PROJECT_ELM_TEST_RUNNER = "elm-test-rs";
          };

          packages = [
            #
            # I'm using Elm 0.19.3 but elm-test-rs requires 0.19.1 or 0.19.2 to run the checks.
            # Why? The registry.dat file it uses is in the 0.19.1 format.
            # The simplest solution for now is to just disable those checks.
            #
            (pkgs.elmPackages.elm-test-rs.overrideAttrs { doCheck = false; })
          ];
        };
      }
    );
}
