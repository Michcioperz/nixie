# kudos to ptrcnull for helping me understand this
self: super: {
  unstable = import <unstable> {
    overlays = [ (import ./overlay/default.nix) ];
  };
}
