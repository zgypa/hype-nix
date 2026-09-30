{
  lib,
  stdenv,
  fetchFromGitHub,
  qmake,
  wrapQtAppsHook,
  qtbase,
  qtdeclarative,
  qtmultimedia,
  qtimageformats,
  qtsvg,
  qtwayland,
  zlib,
  libwebp,
  ffmpeg,
  sourceHighlight,
  python3,
  makeFontsConf,
  dejavu_fonts,
}:

assert lib.assertMsg (lib.versionAtLeast qtbase.version "6.9")
  "Hype requires Qt >= 6.9; use this flake's pinned nixpkgs or a compatible package set.";

stdenv.mkDerivation {
  pname = "hype";
  version = "0.4.3";

  src = fetchFromGitHub {
    owner = "omacom";
    repo = "hype";
    # Upstream v0.4.3, pinned to the commit rather than a movable tag.
    rev = "f9eefda3ee267ad0c747c2456651084f780de02a";
    hash = "sha256-GOhNOPuOf4eXcXUZfylJYccUW7vsifAahqOIBzytZ48=";
  };

  nativeBuildInputs = [ qmake wrapQtAppsHook ];
  buildInputs = [
    qtbase
    qtdeclarative
    qtmultimedia
    qtimageformats
    qtsvg
    qtwayland
    zlib
    libwebp
  ];

  qmakeFlags = [ "hype.pro" ];
  enableParallelBuilding = true;

  # These are external programs Hype starts through QProcess. Put them in
  # the application's wrapper so users need not install them separately.
  preFixup = ''
    qtWrapperArgs+=(--prefix PATH : ${lib.makeBinPath [ ffmpeg sourceHighlight ]})
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 hype "$out/bin/hype"
    install -Dm644 pkgbuild/hype.desktop "$out/share/applications/hype.desktop"
    install -Dm644 pkgbuild/hype.svg "$out/share/icons/hicolor/scalable/apps/hype.svg"
    install -Dm644 LICENSE "$out/share/licenses/hype/LICENSE"
    runHook postInstall
  '';

  # Exercise the installed Qt wrapper, rendering, themes and PDF/PPTX
  # export with upstream's existing headless CLI tests.
  doInstallCheck = true;
  nativeInstallCheckInputs = [ python3 ];
  installCheckPhase = ''
    runHook preInstallCheck
    export FONTCONFIG_FILE=${makeFontsConf {
      fontDirectories = [ dejavu_fonts ];
    }}
    substitute tests/test_cli.py test-installed-cli.py \
      --replace-fail "APP = Path(__file__).resolve().parents[1] / 'build/hype'" \
      "APP = Path('$out/bin/hype')"
    python3 test-installed-cli.py -v
    runHook postInstallCheck
  '';

  meta = {
    description = "Simple Markdown presentations with a visual slide editor";
    homepage = "https://github.com/omacom/hype";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    mainProgram = "hype";
  };
}
