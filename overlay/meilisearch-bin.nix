{ stdenv, pkgs, fetchurl, ... }:
stdenv.mkDerivation rec {
  pname = "meilisearch";
  version = "0.19.0";
  src = fetchurl {
    url = "https://github.com/meilisearch/MeiliSearch/releases/download/v${version}/meilisearch-linux-amd64";
    sha256 = "1qcimnyf4j6wv3lpw0g27jg8xf1mxz1z79snzh0m457n19g62f1h";
  };
  phases = "installPhase";
  installPhase = ''
    install -Dm755 $src $out/bin/meilisearch
  '';
}
