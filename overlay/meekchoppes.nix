{ fetchFromGitHub, lib, stdenv, pkgs }:
stdenv.mkDerivation {
  pname = "meekchoppes";
  version = "0.1.0";
  src = fetchFromGitHub {
    owner = "michcioperz";
    repo = "hugoblog";
    rev = "refs/heads/main";
    sha256 = "0m41a0dssypxz1k7ijp4bm9ffb2rrpq7zzkg1m4bi9gd4pk7yxw1";
  };
  meta = with lib; {
    description = "websites of michcioperz";
    homepage = "https://github.com/michcioperz/hugoblog";
    platforms = platforms.unix;
  };
  nativeBuildInputs = [ pkgs.git pkgs.hugo ];
  installPhase = ''
    hugo --destination $out/share/meekchoppes
  '';
  dontBuild = true;
}
