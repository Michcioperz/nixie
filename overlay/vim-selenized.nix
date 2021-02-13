{ vimUtils, pkgs, ... }:
vimUtils.buildVimPluginFrom2Nix {
  pname = "vim-selenized";
  version = "2020-05-06";
  src = pkgs.fetchFromGitHub {
    owner = "jan-warchol";
    repo = "selenized";
    rev = "e93e0d9fb47c7485f18fa16f9bdb70c2ee7fb5db";
    sha256 = "07mnfkhjs76z7zxdq08rpsaysb517h8sm51a2iv87mgxjk30pqxg";
  } + "/editors/vim";
  meta.homepage = "https://github.com/jan-warchol-selenized";
}
