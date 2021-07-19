{ lib, buildGoModule, fetchFromGitHub, ffmpeg }:
buildGoModule rec {
  pname = "owncast";
  version = "0.0.7";
  src = fetchFromGitHub {
    owner = "owncast";
    repo = "owncast";
    rev = "v${version}";
    sha256 = "1mgkkad3asw6c7mrsaxx72zjbxzd4i9l4jk0m2wbhmpxlkf70vff";
  };
  vendorSha256 = "1yljx7yq285z27hzbhpxwvajnarpg333rk0003929dnbk86pq7lc";
  propagatedBuildInputs = [ ffmpeg ];
  meta = with lib; {
    description = "self-hosted video live streaming solution";
    homepage = "https://owncast.online";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
