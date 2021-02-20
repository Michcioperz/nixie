{ pkgs, ... }:
let
  # vendoring this
  seccomp_2_3_3 = pkgs.stdenv.mkDerivation rec {
    pname = "libseccomp";
    version = "2.3.3";

    src = pkgs.fetchurl {
      url = "https://github.com/seccomp/libseccomp/releases/download/v${version}/libseccomp-${version}.tar.gz";
      sha256 = "0mdiyfljrkfl50q1m3ws8yfcyfjwf1zgkvcva8ffcwncji18zhkz";
    };

    #outputs = [ "out" "lib" "dev" "man" ];

    nativeBuildInputs = [ pkgs.gperf ];
    buildInputs = [ pkgs.getopt ];

    patchPhase = ''
      patchShebangs .
    '';

    checkInputs = [ pkgs.utillinux ];
    doCheck = false; # dependency cycle

    # Hack to ensure that patchelf --shrink-rpath get rids of a $TMPDIR reference.
    preFixup = "rm -rfv src";

    meta = with pkgs.lib; {
      description = "High level library for the Linux Kernel seccomp filter";
      homepage = "https://github.com/seccomp/libseccomp";
      license = licenses.lgpl21;
      platforms = platforms.linux;
      badPlatforms = [
        "alpha-linux"
        "riscv32-linux"
        "sparc-linux"
        "sparc64-linux"
      ];
    };
  };
in
pkgs.multiStdenv.mkDerivation {
  pname = "sio2jail";
  version = "1.3.0";
  src = pkgs.fetchFromGitHub {
    owner = "sio2project";
    repo = "sio2jail";
    rev = "v1.3.0";
    sha256 = "1qn3xvycb1n8qp6zdnpz6f7zpc9kzc2rx6jk5l48mbb2rh9c2nc1";
  };
  buildInputs = [ pkgs.cmake pkgs.ninja pkgs.tclap pkgs.libcap pkgs.scdoc pkgs.glibc.static pkgs.pkgsi686Linux.glibc.static seccomp_2_3_3 ];
  nativeBuildInputs = [ pkgs.breakpointHook ];

  configurePhase = ''
    cmake -G Ninja -DLINK=DYNAMIC -DLIBSECCOMP_BUILD_OWN=NO .
  '';
  buildPhase = ''
    ninja
  '';
  installPhase = ''
    ninja install
  '';
  checkPhase = ''
    ninja test
  '';
}
