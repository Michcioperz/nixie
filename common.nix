{ config, pkgs, ... }:
{
  nixpkgs.overlays = [
    (import ./overlay/default.nix)
  ];

  nix.autoOptimiseStore = true;

  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
  environment.shellAliases = {
    ll = "ls -l";
    vi = "nvim";
  };
}
