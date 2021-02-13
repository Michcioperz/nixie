{ fetchgit, lib, stdenv, pkgs }:
stdenv.mkDerivation {
  pname = "meekchoppes";
  version = "0.1.0";
  src = fetchgit {
    url = "https://git.hinata.iscute.ovh/hugoblog/";
    rev = "refs/heads/main";
    sha256 = "1a3mg8ll06l7iw5zsw0jjs9cznxfx1skc5k3vgaakb7bifqzrjs3";
  };
  meta = with lib; {
    description = "websites of michcioperz";
    homepage = "https://git.hinata.iscute.ovh/hugoblog/";
    platforms = platforms.unix;
  };
  installPhase = ''
    ${pkgs.hugo}/bin/hugo --destination $out/share/meekchoppes
  '';
  dontBuild = true;
}
