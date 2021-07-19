{ fetchFromGitHub, lib, stdenv, pkgs }:
stdenv.mkDerivation {
  pname = "metro-bieszczady-frontend";
  version = "0.1.0";
  src = fetchFromGitHub {
    owner = "michcioperz";
    repo = "metro-bieszczady";
    rev = "refs/heads/main";
    sha256 = "0cc122gh13sa954a1r3kx6kpb3s4n3d7wrnzkm09kk54k8syd6kc";
  };
  meta = with lib; {
    description = "frontend of metro-bieszczady";
    homepage = "https://github.com/michcioperz/metro-bieszczady";
    platforms = platforms.unix;
  };
  nativeBuildInputs = [ pkgs.nodejs pkgs.nodePackages.typescript ];
  buildPhase = ''
    cd frontend
    tsc
  '';
  installPhase = ''
    mkdir -p $out
    cp index.html *.css *.d.ts *.js $out/
  '';
}
