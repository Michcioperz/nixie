{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "ipmi-exporter";
  version = "1.3.1";
  src = fetchFromGitHub {
    owner = "soundcloud";
    repo = "ipmi_exporter";
    rev = "v${version}";
    sha256 = "0pm71p0hfnhwy5q1g2bdvv5zdjrs49a3jargqfa1izp068rsibna";
  };
  vendorSha256 = null;
  meta = with lib; {
    description = "remote IPMI exporter for Prometheus";
    homepage = "https://github.com/soundcloud/ipmi_exporter";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
