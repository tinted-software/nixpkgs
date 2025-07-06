{
  lib,
  stdenv,
  fetchFromGitHub,
  autogen,
  autoconf,
  automake,
  autoreconfHook,
  # By default, jemalloc puts a je_ prefix onto all its symbols on OSX, which
  # then stops downstream builds (mariadb in particular) from detecting it. This
  # option should remove the prefix and give us a working jemalloc.
  # Causes segfaults with some software (ex. rustc), but defaults to true for backward
  # compatibility.
  stripPrefix ? stdenv.hostPlatform.isDarwin,
  disableInitExecTls ? false,
}:

stdenv.mkDerivation rec {
  pname = "jemalloc";
  version = "5.3.0";

  src = fetchFromGitHub {
    owner = "facebook";
    repo = "jemalloc";
    rev = "fb52eac3720b09b4fc163878e7770336f1b6e7f8";
    hash = "sha256-cVBGo3Qm7jxiJE1qWjiSByXlQvRuGoS+yyGTu3GhA0o=";
    # TODO: upstream to nixpkgs: https://github.com/facebook/jemalloc/issues/15
    # tag = version;
  };

  patches = [
    # -O3 appears to introduce an unreproducibility where
    # `rtree_read.constprop.0` shows up in some builds but
    # not others, so we fall back to O2:
    ./o3-to-o2.patch
  ];

  nativeBuildInputs = [
    autogen
    autoconf
    automake
    autoreconfHook
  ];

  configureFlags =
    [
      "--with-version=${version}-0-g0000000000000000000000000000000000000000"
      "--with-lg-vaddr=${with stdenv.hostPlatform; toString (if isILP32 then 32 else parsed.cpu.bits)}"
    ]
    # see the comment on stripPrefix
    ++ lib.optional stripPrefix "--with-jemalloc-prefix="
    ++ lib.optional disableInitExecTls "--disable-initial-exec-tls"
    # jemalloc is unable to correctly detect transparent hugepage support on
    # ARM (https://github.com/jemalloc/jemalloc/issues/526), and the default
    # kernel ARMv6/7 kernel does not enable it, so we explicitly disable support
    ++ lib.optionals (stdenv.hostPlatform.isAarch32 && lib.versionOlder version "5") [
      "--disable-thp"
      "je_cv_thp=no"
    ]
    # The upstream default is dependent on the builders' page size
    # https://github.com/jemalloc/jemalloc/issues/467
    # https://sources.debian.org/src/jemalloc/5.3.0-3/debian/rules/
    ++ [
      (
        if (stdenv.hostPlatform.isAarch64 || stdenv.hostPlatform.isLoongArch64) then
          "--with-lg-page=16"
        else
          "--with-lg-page=12"
      )
    ]
    # See https://github.com/jemalloc/jemalloc/issues/1997
    # Using a value of 48 should work on both emulated and native x86_64-darwin.
    ++ lib.optional (stdenv.hostPlatform.isDarwin && stdenv.hostPlatform.isx86_64) "--with-lg-vaddr=48";

  env.NIX_CFLAGS_COMPILE = lib.optionalString stdenv.hostPlatform.isDarwin "-Wno-error=array-bounds";

  # Tries to link test binaries binaries dynamically and fails
  doCheck = !stdenv.hostPlatform.isStatic;

  doInstallCheck = true;
  installCheckPhase = ''
    ! grep missing_version_try_git_fetch_tags $out/include/jemalloc/jemalloc.h
  '';

  # Parallel builds break reproducibility.
  enableParallelBuilding = true;

  meta = with lib; {
    homepage = "https://jemalloc.net/";
    description = "General purpose malloc(3) implementation";
    longDescription = ''
      malloc(3)-compatible memory allocator that emphasizes fragmentation
      avoidance and scalable concurrency support.
    '';
    license = licenses.bsd2;
    platforms = platforms.all;
  };
}
