{ lib, fetchFromGitHub, rustPlatform, pkg-config, ncurses, openssl
, withALSA ? true, alsaLib ? null
, withPulseAudio ? false, libpulseaudio ? null
, withPortAudio ? false, portaudio ? null
, withMPRIS ? false, withNotify ? false, dbus ? null
, withShareClipboard ? false, libxcb ? null, python3 ? null
}:

let
  features = [ "cursive/pancurses-backend" ]
    ++ lib.optional withALSA "alsa_backend"
    ++ lib.optional withPulseAudio "pulseaudio_backend"
    ++ lib.optional withPortAudio "portaudio_backend"
    ++ lib.optional withMPRIS "mpris"
    ++ lib.optional withShareClipboard "share_clipboard"
    ++ lib.optional withNotify "notify";
in
rustPlatform.buildRustPackage rec {
  pname = "ncspot";
  version = "0.4.0+1";

  src = fetchFromGitHub {
    owner = "hrkfdn";
    repo = "ncspot";
    rev = "dfb60ee4bee283e27599f02ef1d28ff68d88258a";
    sha256 = "1sn44ik080228r2n1vf64qppv9x3m3ni9jzqvcpqmk68nwizqhdh";
  };

  cargoSha256 = "0dpsx0v479naswpy9brd17xf2gfbnvw1zb073hlg1k9ma3jly0ma";

  cargoBuildFlags = [ "--no-default-features" "--features" "${lib.concatStringsSep "," features}" ];

  nativeBuildInputs = [ pkg-config ]
    ++ lib.optional withShareClipboard python3;

  buildInputs = [ ncurses openssl ]
    ++ lib.optional withALSA alsaLib
    ++ lib.optional withPulseAudio libpulseaudio
    ++ lib.optional withPortAudio portaudio
    ++ lib.optional (withMPRIS || withNotify) dbus
    ++ lib.optional withShareClipboard libxcb;

  doCheck = false;

  meta = with lib; {
    description = "Cross-platform ncurses Spotify client written in Rust, inspired by ncmpc and the likes";
    homepage = "https://github.com/hrkfdn/ncspot";
    license = licenses.bsd2;
    maintainers = [ maintainers.marsam ];
  };
}
