{
  brotli,
  cmake,
  pkg-config,
  fetchFromGitHub,
  lib,
  stdenv,
  static ? stdenv.hostPlatform.isStatic,
}:

stdenv.mkDerivation rec {
  pname = "woff2";
  version = "82ef3229b13b0741bb320412cbda4d43173abf3f";

  src = fetchFromGitHub {
    owner = "tinted-software";
    repo = "woff2";
    rev = "${version}";
    hash = "sha256-7RQMwDPZ0wSwAXamhHPkB64BqGswD36y0n4h+H31zec=";
  };

  outputs = [
    "out"
    "dev"
    "lib"
  ];

  # Need to explicitly link to brotlicommon
  patches = lib.optional static ./brotli-static.patch;

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  cmakeFlags = [
    "-DCANONICAL_PREFIXES=ON"
    "-DBUILD_SHARED_LIBS=${if static then "OFF" else "ON"}"
  ] ++ lib.optional static "-DCMAKE_SKIP_RPATH:BOOL=TRUE";

  propagatedBuildInputs = [ brotli ];

  postPatch = ''
    # without this binaries only get built if shared libs are disable
    sed 's@^if (NOT BUILD_SHARED_LIBS)$@if (TRUE)@g' -i CMakeLists.txt
  '';

  meta = with lib; {
    description = "Webfont compression reference code";
    homepage = "https://github.com/google/woff2";
    license = licenses.mit;
    maintainers = [ maintainers.hrdinka ];
    platforms = platforms.unix;
  };
}
