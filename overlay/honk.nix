{ buildGoModule, fetchhg, lib, pkgs }:
buildGoModule rec {
  pname = "honk";
  version = "0.9.5";
  src = fetchhg {
    url = "https://humungus.tedunangst.com/r/honk";
    rev = "v${version}";
    sha256 = "0ilsrpbxa3xw0wqzvfbfjqkxv5wgi0s113gwl3a0iw1s4j4ly8by";
  };
  buildInputs = [ pkgs.sqlite ];
  vendorSha256 = "027vwjjbiiv3gkb4fxbl9p3ha15i1ib3j49cba3v14fwxscfjigx";
  subPackages = ["."];
  #runVend = true;
  meta = with lib; {
    description = "ActivityPub server";
    homepage = "https://humungus.tedunangst.com/r/honk";
    license = licenses.isc;
  };
}
