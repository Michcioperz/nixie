self: super:
{
  ipmi-exporter = super.callPackage ./ipmi-exporter.nix { };
  meekchoppes = super.callPackage ./meekchoppes.nix { };
  rustagit = super.callPackage ./rustagit.nix { };
  umiarkonowy = super.callPackage ./umiarkonowy.nix { };
  scoobideria = super.callPackage ./scoobideria.nix { };
  sccache-dist = super.callPackage ./sccache-dist.nix { };
  honk = super.callPackage ./honk.nix { };
  czy-piec-siedem = super.callPackage ./czy-piec-siedem.nix { };
}
