{
  lib,
  stdenv,
  fetchurl,
  readline,
  libmysqlclient,
  libpq,
  sqlite,
}:

let
  inherit (lib) getDev;
in

stdenv.mkDerivation rec {
  pname = "opendbx";
  version = "1.4.6";

  src = fetchurl {
    url = "https://linuxnetworks.de/opendbx/download/opendbx-${version}.tar.gz";
    sha256 = "0z29h6zx5f3gghkh1a0060w6wr572ci1rl2a3480znf728wa0ii2";
  };

  preConfigure = ''
    export CPPFLAGS="-I${getDev libmysqlclient}/include/mysql"
    export LDFLAGS="-L${libmysqlclient}/lib/mysql"
    configureFlagsArray=(--with-backends="mysql pgsql sqlite3")
  '';

  configureFlags = [
    # detection fails when cross-compiling
    "ac_cv_func_malloc_0_nonnull=yes"
    "ac_cv_func_realloc_0_nonnull=yes"
    "ac_cv_func_strtod=yes"
  ];

  buildInputs = [
    readline
    libmysqlclient
    libpq
    sqlite
  ];

  env.NIX_CFLAGS_COMPILE = toString [
    # Needed with GCC 12
    "-std=c++14"
  ];

  meta = with lib; {
    broken = stdenv.hostPlatform.isDarwin;
    description = "Extremely lightweight but extensible database access library written in C";
    mainProgram = "odbx-sql";
    license = licenses.lgpl21;
    platforms = platforms.all;
  };
}
