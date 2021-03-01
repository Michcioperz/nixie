{ lib, stdenv
, rustPlatform
, fetchFromGitHub
}:

rustPlatform.buildRustPackage rec {
  pname = "meilisearch";
  version = "0.19.0";

  src = fetchFromGitHub {
    owner = "meilisearch";
    repo = "MeiliSearch";
    rev = "v${version}";
    sha256 = "0n43xnnj8671jbbj3620lfim354n7iyhc0vdfkhqv7fnryxvvriz";
  };

  cargoSha256 = "0n43xnnj8671jbbj3620lfim354n7iyhc0vdfkhqv7fnryxvvriz";

  meta = with lib; {
    description = "Ultra relevant and instant full-text search API";
    homepage = "https://meilisearch.com/";
    license = licenses.mit;
  };
}
