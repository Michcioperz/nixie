{ lib, fetchFromGitHub, rustPlatform, python3Packages }:
python3Packages.buildPythonApplication rec {
  pname = "scoobideria";
  version = "0.1.0";
  src = fetchFromGitHub {
    owner = "michcioperz";
    repo = "scoobideria";
    rev = "refs/heads/main";
    sha256 = "1md6am6xy418gw5q7817229yik14hwsz525iixxba9frbzx8bv73";
  };
  cargoDeps = rustPlatform.fetchCargoTarball {
    inherit src;
    sha256 = "12f4maqfaw60l6apw69kc3llk2ark6gagi0wy398xi7pkvz219hk";
  };
  propagatedBuildInputs = with python3Packages; [ python-telegram-bot ];
  nativeBuildInputs = with rustPlatform; [ cargoSetupHook maturinBuildHook ];
  doCheck = false;
  meta = with lib; {
    description = "telegram roll bot";
    homepage = "https://github.com/michcioperz/scoobideria";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
