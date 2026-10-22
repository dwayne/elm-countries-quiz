{ deploy
, elm2nixLib
, elmPackages
, just
, mkShell
, nodejs
, pnpm
}:

mkShell {
  name = "shell";

  packages = [
    deploy
    elm2nixLib.elm2nix
    elmPackages.elm
    elmPackages.elm-format
    elmPackages.elm-json
    elmPackages.elm-review
    elmPackages.elm-test
    just
    nodejs
    pnpm
  ];

  shellHook = ''
    export PROJECT_ROOT="$PWD"
    export PATH="$PROJECT_ROOT/node_modules/.bin:$PATH"

    if [ ! -d "$PROJECT_ROOT/node_modules" ]; then
      pnpm install --loglevel warn
    fi
  '';
}
