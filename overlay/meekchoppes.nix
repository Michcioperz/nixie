{ fetchgit, lib, stdenv, pkgs }:
stdenv.mkDerivation {
  pname = "meekchoppes";
  version = "0.1.0";
  src = fetchgit {
    url = "https://git.hinata.iscute.ovh/hugoblog/";
    rev = "refs/heads/main";
    sha256 = "0czxzdv8haqqlahvra42b7vpxbl0r8dvqvfmknbxjxdji5hvgqk6";
  };
  meta = with lib; {
    description = "websites of michcioperz";
    homepage = "https://git.hinata.iscute.ovh/hugoblog/";
    platforms = platforms.unix;
  };
  nativeBuildInputs = [ pkgs.git pkgs.hugo ];
  installPhase = ''
    hugo --destination $out/share/meekchoppes
  '';
  dontBuild = true;
}
