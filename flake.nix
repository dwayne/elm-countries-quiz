{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-elm2nix = {
      url = "github:dwayne/elm2nix/use-elm-0.19.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-deploy = {
      url = "github:dwayne/deploy";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-elm2nix, flake-deploy }:
    let
      lib = nixpkgs.lib;
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
      eachSupportedSystem = f: lib.foldAttrs lib.mergeAttrs {} (map (s: lib.mapAttrs (_: v: { ${s} = v; }) (f s)) supportedSystems);
    in
    eachSupportedSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ flake-elm2nix.overlays.default ];
        };

        elm2nixLib = flake-elm2nix.lib.mkLib pkgs;
        deploy = flake-deploy.lib.mkDeploy pkgs;

        project = pkgs.callPackage ./nix {
          inherit elm2nixLib deploy;
        };

        site = project.build {
          name = "elm-countries-quiz";
          root = ./.;
          hash = "sha256-5AIGDUe9QgFJIE5UlUi9Q2o8RlOzIacNAA8rjeKOAK0=";
          extraPaths = [ ".postcssrc" "tailwind.config.js" ];
          patches = flake-elm2nix.lib.elmSafeVirtualDomPatches.default;
        };
      in
      {
        devShells.default = pkgs.mkShell {
          name = "elm-countries-quiz";

          inputsFrom = [ project.devShell ];

          packages = [
            pkgs.elmPackages.elm-json
            pkgs.elmPackages.elm-review

            #
            # I'm using Elm 0.19.3 but elm-test-rs requires 0.19.1 or 0.19.2 to run the checks.
            # Why? The registry.dat file it uses is in the 0.19.1 format.
            # The simplest solution for now is to just disable those checks.
            #
            (pkgs.elmPackages.elm-test-rs.overrideAttrs { doCheck = false; })
          ];

          shellHook = ''
            f () {
              elm-format                   \
                "$PROJECT_ROOT"/src        \
                "$PROJECT_ROOT"/review/src \
                "$PROJECT_ROOT"/tests      \
                --yes
            }

            r () {
              elm-review
            }

            t () {
              elm-test-rs "$PROJECT_ROOT"/tests/*.elm
            }

            c () {
              rm -rf "$PROJECT_ROOT"/{.parcel-cache,dist,elm-stuff,node_modules}
            }

            s () {
              pnpm dev
            }

            echo "Elm development environment loaded"
            echo "All your dependencies have been installed"
            echo ""
            echo "Type 'f' to run elm-format"
            echo "Type 'r' to run elm-review"
            echo "Type 't' to run elm-test-rs"
            echo "Type 'c' to remove build artifacts"
            echo "Type 's' to start the development server"
            echo ""
          '';
        };

        packages = {
          inherit site;
          default = site;
        };

        apps = {
          inherit (site) serve deploy;
          default = site.serve;
        };

        checks = { inherit site; };
      }
    );
}
