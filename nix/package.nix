{
  buildGoModule,
  git,
  go,
  lib,
  makeWrapper,
  nodejs,
  pnpm,
  stdenv,
  ...
}: let
  headplane-wasm =
    (buildGoModule {
      pname = "hp_ssh";
      version = (builtins.fromJSON (builtins.readFile ../package.json)).version;
      src = ../.;
      vendorHash = "sha256-3hZzDORAH+D4FW6SkOv3Enddd+q36ZALryvCPD9E5Ac=";
      subPackages = ["cmd/hp_ssh"];
    }).overrideAttrs (old:
      old
      // {
        env.GOOS = "js";
        env.GOARCH = "wasm";
      });
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "headplane";
    version = (builtins.fromJSON (builtins.readFile ../package.json)).version;
    src = ../.;

    nativeBuildInputs = [
      git
      makeWrapper
      nodejs
      pnpm.configHook
    ];

    dontCheckForBrokenSymlinks = true;

    pnpmDeps = pnpm.fetchDeps {
      inherit (finalAttrs) pname version src;
      hash = "sha256-zK9yxTHgtZ8ybVsjmY/ZoScOWu5kpvEL6pVdpQZOYA8=";
    };

    buildPhase = ''
      runHook preBuild

      cp ${headplane-wasm}/bin/js_wasm/hp_ssh ./app/hp_ssh.wasm
      cat $(${go}/bin/go env GOROOT)/lib/wasm/wasm_exec.js >> ./app/wasm_exec.js

      pnpm build

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/{bin,share/headplane}

      cp -r build $out/share/headplane/
      cp -r drizzle $out/share/headplane/
      cp -r node_modules $out/share/headplane/

      makeWrapper ${lib.getExe nodejs} $out/bin/headplane \
          --chdir $out/share/headplane \
          --add-flags $out/share/headplane/build/server/index.js

      runHook postInstall
    '';
  })
