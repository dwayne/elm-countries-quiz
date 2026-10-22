{ deploy
, elmPackages
, elm2nixLib
, fetchPnpmDeps
, lib
, mkServe
, nodejs
, pnpm
, pnpmConfigHook
, stdenv
, writeShellApplication
}:

lib.makeOverridable (
  { name
  , root
  , hash
  , defaultPaths ? [ "src" "elm.json" "package.json" "pnpm-lock.yaml" "pnpm-workspace.yaml" ]
  , extraPaths ? []
  , elmLockFilename ? "elm.lock"
  , patches ? []
  , port ? 8000
  , deployBranch ? "gh-pages"
  }:
  let
    fs = lib.fileset;
    paths = defaultPaths ++ extraPaths;

    elmLock = root + "/${elmLockFilename}";
    registryDat = elm2nixLib.generateRegistryDat { inherit elmLock; };
  in
  stdenv.mkDerivation (finalAttrs: {
    inherit name;

    src = fs.toSource {
      inherit root;
      fileset = fs.unions (builtins.map (path: root + "/${path}") paths);
    };

    nativeBuildInputs = [
      elmPackages.elm
      nodejs
      pnpmConfigHook
      pnpm
    ];

    pnpmDeps = fetchPnpmDeps {
      inherit (finalAttrs) src;
      inherit hash;
      pname = finalAttrs.name;
      fetcherVersion = 4;
    };

    buildPhase = ''
      runHook preBuild

      ${elm2nixLib.prepareElmHomeScript { inherit elmLock registryDat; }}
      ${elm2nixLib.installPatchesScript patches}

      pnpm build

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      cp -r dist "$out"

      runHook postInstall
    '';

    passthru =
      let
        serveDrv = mkServe {
          inherit port;
          name = "serve-${finalAttrs.name}";
          root = finalAttrs.finalPackage;
        };

        serveApp = {
          type = "app";
          program = lib.getExe serveDrv;
          meta.description = "Serve ${finalAttrs.name}";
        };

        deployDrv = writeShellApplication {
          name = "deploy-${finalAttrs.name}";
          runtimeInputs = [ deploy ];
          text = ''
            exec deploy "$@" "${finalAttrs.finalPackage}" "${deployBranch}"
          '';
        };

        deployApp = {
          type = "app";
          program = lib.getExe deployDrv;
          meta.description = "Deploy ${finalAttrs.name}";
        };
      in
      {
        inherit serveDrv deployDrv;
        serve = serveApp;
        deploy = deployApp;
      };
  })
)
