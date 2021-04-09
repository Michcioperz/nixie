{ lib, fetchFromGitHub, rustPlatform, pkgs, cmake, pkgconfig, cargo, rustc, openssl }:
rustPlatform.buildRustPackage rec {
  pname = "czy-piec-siedem";
  version = "0.1.0";
  src = fetchFromGitHub {
    owner = "michcioperz";
    repo = "czy-piec-siedem";
    rev = "refs/heads/main";
    sha256 = "0a1nljgn433jm4cal10mixq4nn116n5b9jl4wjxq3pm9kpxz32q9";
  };
  cargoSha256 = "0n9b9walgbpjbnldc176qxj1qi86msl546516g6qy5p4hsc10vw7";
  nativeBuildInputs = [ cargo rustc ];
  meta = with lib; {
    description = "radio schedule extractor";
    homepage = "https://github.com/michcioperz/czy-piec-siedem/";
    platforms = platforms.unix;
  };
}
