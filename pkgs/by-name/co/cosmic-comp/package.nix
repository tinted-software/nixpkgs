{ lib
, stdenv
, rustPlatform
, fetchFromGitHub
, makeBinaryWrapper
, pkg-config
, libinput
, libglvnd
, libxkbcommon
, mesa
, seatd
, udev
, xwayland
, wayland
, xorg
, useXWayland ? true
, systemd
, useSystemd ? lib.meta.availableOn stdenv.hostPlatform systemd
}:

rustPlatform.buildRustPackage rec {
  pname = "cosmic-comp";
  version = "unstable-2024-08-07";

  src = fetchFromGitHub {
    owner = "pop-os";
    repo = "cosmic-comp";
    rev = "5537fa48228f598be47ebe4ecd6b741fd7d7aafa";
    hash = "sha256-1LBTyv0QImA0LcWOD0VTHtSzaed4Bjh2gsCcDPLYDGI=";
  };

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    outputHashes = {
      "cosmic-config-0.1.0" = "sha256-nZCefRCq40K0Mcsav+akZbX89kHnliqAkB7vKx5WIwY=";
      "cosmic-protocols-0.1.0" = "sha256-qgo8FMKo/uCbhUjfykRRN8KSavbyhZpu82M8npLcIPI=V";
      "id_tree-1.8.0" = "sha256-uKdKHRfPGt3vagOjhnri3aYY5ar7O3rp2/ivTfM2jT0=";
      "smithay-0.3.0" = "sha256-puo6xbWRTIco8luz3Jz83VXoRMkyb0ZH7kKHGlTzS5Q=";
      "smithay-egui-0.1.0" = "sha256-FcSoKCwYk3okwQURiQlDUcfk9m/Ne6pSblGAzHDaVHg=";
      "taffy-0.3.11" = "sha256-SCx9GEIJjWdoNVyq+RZAGn0N71qraKZxf9ZWhvyzLaI=";
      "atomicwrites-0.4.2" = "sha256-QZSuGPrJXh+svMeFWqAXoqZQxLq/WfIiamqvjJNVhxA=";
      "clipboard_macos-0.1.0" = "sha256-cG5vnkiyDlQnbEfV2sPbmBYKv1hd3pjJrymfZb8ziKk=";
      "cosmic-settings-config-0.1.0" = "sha256-/Qav6r4VQ8ZDSs/tqHeutxYH3u4HiTBFWTfAYUSl2HQ=v";
      "cosmic-text-0.12.1" = "sha256-x0XTxzbmtE2d4XCG/Nuq3DzBpz15BbnjRRlirfNJEiU=";
      "d3d12-0.19.0" = "sha256-usrxQXWLGJDjmIdw1LBXtBvX+CchZDvE8fHC0LjvhD4=";
      "glyphon-0.5.0" = "sha256-j1HrbEpUBqazWqNfJhpyjWuxYAxkvbXzRKeSouUoPWg=V";
      "smithay-clipboard-0.8.0" = "sha256-4InFXm0ahrqFrtNLeqIuE3yeOpxKZJZx+Bc0yQDtv34=";
      "softbuffer-0.4.1" = "sha256-a0bUFz6O8CWRweNt/OxTvflnPYwO5nm6vsyc/WcXyNg=";
    };
  };

  separateDebugInfo = true;

  nativeBuildInputs = [ makeBinaryWrapper pkg-config ];
  buildInputs = [
      libglvnd
      libinput
      libxkbcommon
      mesa
      seatd
      udev
      wayland
    ] ++ lib.optional useSystemd systemd;

  # Only default feature is systemd
  buildNoDefaultFeatures = !useSystemd;

  # Force linking to libEGL, which is always dlopen()ed, and to
  # libwayland-client, which is always dlopen()ed except by the
  # obscure winit backend.
  RUSTFLAGS = map (a: "-C link-arg=${a}") [
    "-Wl,--push-state,--no-as-needed"
    "-lEGL"
    "-lwayland-client"
    "-Wl,--pop-state"
  ];

  # These libraries are only used by the X11 backend, which will not
  # be the common case, so just make them available, don't link them.
  postInstall = ''
    wrapProgramArgs=(--prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [
        xorg.libX11 xorg.libXcursor xorg.libXi xorg.libXrandr
    ]})
  '' + lib.optionalString useXWayland ''
    wrapProgramArgs+=(--prefix PATH : ${lib.makeBinPath [ xwayland ]})
  '' + ''
    wrapProgram $out/bin/cosmic-comp "''${wrapProgramArgs[@]}"
  '';

  meta = with lib; {
    homepage = "https://github.com/pop-os/cosmic-comp";
    description = "Compositor for the COSMIC Desktop Environment";
    mainProgram = "cosmic-comp";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ qyliss nyanbinary ];
    platforms = platforms.linux;
  };
}
