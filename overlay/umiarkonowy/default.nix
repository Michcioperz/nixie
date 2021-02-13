{ lib, fetchgit, rustPlatform, pkgs, cmake, pkgconfig, cargo, rustc, openssl }:
rustPlatform.buildRustPackage rec {
  pname = "umiarkonowy";
  version = "0.1.0";
  src = fetchgit {
    url = "https://git.hinata.iscute.ovh/umiarkowanie-nowy-swiat/";
    rev = "refs/heads/main";
    sha256 = "1gyy3885v023liqqhsiyfd9fjxvgkmmwjfn459li82id3xfxfnww";
  };
  cargoSha256 = "1a4s889n2f35pkay0hnygc3qa6jgd0yz69czyj24nrg3sryh5vkm";
  nativeBuildInputs = [ cmake pkgconfig cargo rustc ];
  buildInputs = [ openssl ];
  meta = with lib; {
    description = "radio proxy";
    homepage = "https://git.hinata.iscute.ovh/umiarkowanie-nowy-swiat/";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
