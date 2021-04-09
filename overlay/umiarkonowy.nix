{ lib, fetchFromGitHub, rustPlatform, pkgs, cmake, pkgconfig, cargo, rustc, openssl }:
rustPlatform.buildRustPackage rec {
  pname = "umiarkonowy";
  version = "0.1.1";
  src = fetchFromGitHub {
    owner = "michcioperz";
    repo = "umiarkowanie-nowy-swiat";
    rev = "refs/heads/main";
    sha256 = "1mpn94vyz69sd56513yll4l0r5mf5bcl7rmq53k4z2g6mkd9clbm";
  };
  cargoSha256 = "0ybc1xdm618giy80jznd84wfcvq6gixqy3ahi84yrqmciafhl8n3";
  nativeBuildInputs = [ cmake pkgconfig cargo rustc ];
  buildInputs = [ openssl ];
  meta = with lib; {
    description = "radio proxy";
    homepage = "https://github.com/michcioperz/umiarkowanie-nowy-swiat";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
