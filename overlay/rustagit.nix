{ lib, fetchgit, pkgs, rustPlatform }:
rustPlatform.buildRustPackage rec {
  pname = "rustagit";
  version = "0.1.0";
  src = fetchgit {
    url = "https://git.hinata.iscute.ovh/rustagit/";
    rev = "refs/heads/main";
    sha256 = "0mwjqwh73v8i8iykxyhdxjqfsd5x9a5irj60pxjcknbff4ipd1b0";
  };
  cargoSha256 = "05wv89sm2zx8jd93fv23nyjn7c01qfamzkclcxf00f0bgfg0flmb";
  meta = with lib; {
    description = "static git browser generator";
    homepage = "https://git.hinata.iscute.ovh/rustagit/";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
