self: super:
{
  ipmi-exporter = super.callPackage ./ipmi-exporter { };
  meekchoppes = super.callPackage ./meekchoppes { };
  rustagit = super.callPackage ./rustagit { };
  umiarkonowy = super.callPackage ./umiarkonowy { };
  scoobideria = super.callPackage ./scoobideria { };
  sccache-dist = super.callPackage ./sccache-dist { };
  honk = super.callPackage ./honk.nix { };
  czy-piec-siedem = super.callPackage ./czy-piec-siedem.nix { };
}
