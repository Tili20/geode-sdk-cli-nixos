{
  lib,
  stdenv,
  fetchurl,
  unzip,
  makeWrapper,
  autoPatchelfHook,
  zlib,
  openssl,
  libgcc,
  git,
  gnutar,
  cacert,
}: let
  version = "3.9.0";

  sources = {
    x86_64-linux = {
      url = "https://github.com/geode-sdk/cli/releases/download/v${version}/geode-cli-v${version}-linux.zip";
      hash = "sha256-wccyYZEGumMABFJoSehhfaWIF0bh2BhWRg43sLa5ly0=";
    };
    aarch64-linux = {
      url = "https://github.com/geode-sdk/cli/releases/download/v${version}/geode-cli-v${version}-linux-arm.zip";
      hash = "sha256-5yWJgNGuG3nZhzmQK3EIueCQQ1F/10stnKhw10UHCws=";
    };
    x86_64-darwin = {
      url = "https://github.com/geode-sdk/cli/releases/download/v${version}/geode-cli-v${version}-mac.zip";
      hash = "sha256-lI5JlezmrCWlUWdFqh0PBE1qK38mQWDVNkkjxawC4Yc=";
    };
    aarch64-darwin = sources.x86_64-darwin;
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "geode-sdk-cli: unsupported system ${stdenv.hostPlatform.system}");

  isLinux = stdenv.hostPlatform.isLinux;
in
  stdenv.mkDerivation {
    pname = "geode-sdk-cli";
    inherit version;

    src = fetchurl {
      inherit (source) url hash;
    };

    nativeBuildInputs = [unzip makeWrapper] ++ lib.optionals isLinux [autoPatchelfHook];
    buildInputs = lib.optionals isLinux [zlib openssl libgcc];

    sourceRoot = ".";
    dontConfigure = true;
    dontBuild = true;
    dontStrip = stdenv.hostPlatform.isDarwin;

    installPhase = ''
      runHook preInstall
      install -Dm755 geode $out/bin/geode
      runHook postInstall
    '';

    postFixup = ''
      wrapProgram $out/bin/geode \
        --prefix PATH : ${lib.makeBinPath [git gnutar]} \
        --set SSL_CERT_FILE ${cacert}/etc/ssl/certs/ca-bundle.crt \
        --set GIT_SSL_CAINFO ${cacert}/etc/ssl/certs/ca-bundle.crt
    '';

    meta = {
      description = "Command-line utilities for working with the Geode SDK";
      homepage = "https://github.com/geode-sdk/cli";
      license = lib.licenses.boost;
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      mainProgram = "geode";
    };
  }
