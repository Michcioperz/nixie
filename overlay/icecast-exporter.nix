{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "icecast-exporter";
  version = "0.1.0";
  src = fetchFromGitHub {
    owner = "markuslindenberg";
    repo = "icecast_exporter";
    rev = "ce5cb4055d987ab0f8b95061ef7bf75dc547c787";
    sha256 = "0000000000000000000000000000000000000000000000000000";
  };
  vendorSha256 = null;
  meta = with lib; {
    description = "Icecast exporter for Prometheus";
    homepage = "https://github.com/markuslindenberg/icecast_exporter";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
