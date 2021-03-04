{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "icecast-exporter";
  version = "0.1.0";
  src = fetchFromGitHub {
    owner = "radiofrance";
    repo = "icecast_exporter";
    rev = "800a7c1aa58c1aa2518f57dbcd6c98a7f6c05192";
    sha256 = "16fk144jn5053lm6xqnm1kis3nxqw0sigdmlhr9fvlf6sjfa7cn7";
  };
  vendorSha256 = "0rdwz2k11n5x9xc755mmr3zsdgknqk2f1b5q7rcg5dqlxhycqzw0";

  meta = with lib; {
    description = "Icecast exporter for Prometheus";
    homepage = "https://github.com/radiofrance/icecast_exporter";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
