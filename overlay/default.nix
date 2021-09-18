self: super:
{
  fractalLock = super.writeScriptBin "fractal-lock" ''
    #!${super.stdenv.shell} -e
    f="$(mktemp)"
    ${super.haskellPackages.FractalArt}/bin/FractalArt --no-bg -w 128 -h 128 -f "$f.bmp"
    ${super.imagemagick}/bin/convert "$f.bmp" \( -clone 0 -flip \) -append \( -clone 0 -flop \) +append "$f.png"
    exec ${super.i3lock}/bin/i3lock -i "$f.png" -f -t
  '';
  firefoxNoGtkTheme = super.symlinkJoin {
    name = "firefox";
    paths = [
      (super.writeScriptBin "firefox" ''
        #!${super.stdenv.shell}
        unset GTK_THEME
        exec ${super.firefox}/bin/firefox "$@"
      '')
      super.firefox
    ];
  };
  strawberryProprietary = (super.strawberry.overrideAttrs (old: {
    buildInputs = old.buildInputs ++ (with super.gst_all_1; [ gst-plugins-bad gst-vaapi gst-libav ] ++ [super.libunwind super.elfutils super.orc]);
  })).override { withVlc = false; };
  ncspot = super.ncspot.override {
    withALSA = false;
    withPulseAudio = true;
    withMPRIS = true;
  };
  ncspot-git = super.callPackage ./ncspot-git.nix {
    withALSA = false;
    withPulseAudio = true;
    withMPRIS = true;
    withNotify = true;
    withShareClipboard = true;
  };
  overpass-nerdfont = super.nerdfonts.override { fonts = ["Overpass"]; };
  fantasque-nerdfont = super.nerdfonts.override { fonts = ["FantasqueSansMono"]; };

  icecast-exporter = super.callPackage ./icecast-exporter.nix { };
  ipmi-exporter = super.callPackage ./ipmi-exporter.nix { };
  rustagit = super.callPackage ./rustagit.nix { };
  umiarkonowy = super.callPackage ./umiarkonowy.nix { };
  scoobideria = super.callPackage ./scoobideria.nix { };
  sccache-dist = super.callPackage ./sccache-dist.nix { };
  honk = super.callPackage ./honk.nix { };
  owncast = super.callPackage ./owncast.nix { };
  czy-piec-siedem = super.callPackage ./czy-piec-siedem.nix { };
  vim-selenized = super.callPackage ./vim-selenized.nix { };
  neovim-m314 = super.callPackage ./vimrc.nix { };
  i3spin = super.callPackage ./i3spin.nix { };
  nncp = super.callPackage ./nncp.nix {};
  meilisearch-bin = super.callPackage ./meilisearch-bin.nix {};
  metro-bieszczady-frontend = super.callPackage ./metro-bieszczady-frontend.nix {};
}
