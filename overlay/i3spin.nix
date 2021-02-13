{ rustPlatform, lib, pkgs, ... }:
rustPlatform.buildRustPackage rec {
  pname = "i3spin";
  version = "0.2.0+1";
  src = pkgs.fetchgit {
    url = "https://git.hinata.iscute.ovh/i3spin/";
    rev = "refs/heads/main";
    sha256 = "14y2pxzaywv44wc057m5zi711lh4y0j7h1npq7fdm1z0v3lpaznc";
  };
  cargoSha256 = "0fnfaalb4vmm5yadfxfbwzadsy5fgqdzrb13wm4dsf830xf1afnv";
  meta = with lib; {
    description = "replicates classical DE alt+tab behaviour on i3 window manager";
    homepage = "https://git.hinata.iscute.ovh/i3spin/";
    license = licenses.bsd3;
  };
}
