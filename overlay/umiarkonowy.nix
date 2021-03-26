{ lib, fetchgit, rustPlatform, pkgs, cmake, pkgconfig, cargo, rustc, openssl }:
rustPlatform.buildRustPackage rec {
  pname = "umiarkonowy";
  version = "0.1.1";
  src = fetchgit {
    url = "https://git.hinata.iscute.ovh/umiarkowanie-nowy-swiat/";
    rev = "refs/heads/main";
    sha256 = "1mpn94vyz69sd56513yll4l0r5mf5bcl7rmq53k4z2g6mkd9clbm";
  };
  cargoSha256 = "0ybc1xdm618giy80jznd84wfcvq6gixqy3ahi84yrqmciafhl8n3";
  nativeBuildInputs = [ cmake pkgconfig cargo rustc ];
  buildInputs = [ openssl ];
  meta = with lib; {
    description = "radio proxy";
    homepage = "https://git.hinata.iscute.ovh/umiarkowanie-nowy-swiat/";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
