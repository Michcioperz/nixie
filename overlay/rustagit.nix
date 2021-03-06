{ lib, fetchFromGitHub, pkgs, rustPlatform }:
rustPlatform.buildRustPackage rec {
  pname = "rustagit";
  version = "0.1.0";
  src = fetchFromGitHub {
    owner = "michcioperz";
    repo = "rustagit";
    rev = "refs/heads/main";
    sha256 = "0y43kmlq7yby6x17bfd2pkfdkxc5l6g4mnxaa7dfxkxf1r932r3f";
  };
  cargoSha256 = "0kblrczf4lq4hjyzwvr7ghv1c17sb7knx4clinh4x6dyg8yd1797";
  meta = with lib; {
    description = "static git browser generator";
    homepage = "https://github.com/michcioperz/rustagit";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
