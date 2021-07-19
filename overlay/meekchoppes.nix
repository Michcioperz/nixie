{ fetchFromGitHub, lib, stdenv, pkgs }:
stdenv.mkDerivation {
  pname = "meekchoppes";
  version = "0.1.0";
  src = fetchFromGitHub {
    owner = "michcioperz";
    repo = "hugoblog";
    rev = "refs/heads/main";
    sha256 = "0ihb8nxp7gblga9d0hpd260m3dfivc89f0v93rkgima9bn66ckbi";
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
