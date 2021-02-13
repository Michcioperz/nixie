{ lib, fetchgit, rustPlatform, pkgs, cmake, pkgconfig, cargo, rustc, openssl }:
rustPlatform.buildRustPackage rec {
  pname = "scoobideria";
  version = "0.1.0";
  src = fetchgit {
    url = "https://git.hinata.iscute.ovh/scoobideria/";
    rev = "refs/heads/main";
    sha256 = "1sh362bnfp5rj3a9y5b3r4f74rf9n66fa2f2n2am8fjnvi2alr9f";
  };
  cargoSha256 = "1h9smqvawq34nd70pz5x6g4diy4d9jspsi6lsmpc0vmzj39fd5nk";
  nativeBuildInputs = [ cmake pkgconfig cargo rustc ];
  buildInputs = [ openssl ];
  meta = with lib; {
    description = "telegram roll bot";
    homepage = "https://git.hinata.iscute.ovh/scoobideria/";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
