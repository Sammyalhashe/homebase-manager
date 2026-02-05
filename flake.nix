{
  description = "Homebase Manager - A cross-platform app for managing homelab hosts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            android_sdk.accept_license = true;
          };
        };

        androidComposition = pkgs.androidenv.composeAndroidPackages {
          buildToolsVersions = [ "34.0.0" ];
          platformVersions = [ "34" ];
          abiVersions = [ "x86_64" ];
        };

        androidSdk = androidComposition.androidsdk;
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "homebase-manager";
          version = "0.1.0";
          src = ./.;

          nativeBuildInputs = with pkgs; [
            cmake
            ninja
            pkg-config
            clang
            flutter
          ];

          buildInputs = with pkgs; [
            gtk3
            glib
            pcre2
            libdatrie
            libthai
            libselinux
            libsepol
            util-linux
            libxkbcommon
            dbus
            at-spi2-core
            libepoxy
            xorg.libXdmcp
            xorg.libXtst
          ];

          # Network access is required for `flutter pub get`
          # Build with: nix build --impure
          buildPhase = ''
            export HOME=$(mktemp -d)
            flutter pub get
            flutter build linux --release
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp -r build/linux/x64/release/bundle/* $out/bin/
            # Rename binary if needed, or link
            # ln -s $out/bin/homebase_manager $out/bin/homebase
          '';
        };

        packages.scoop-manifest = pkgs.writeShellScriptBin "generate-scoop" ''
          ${pkgs.dart}/bin/dart run scripts/generate_scoop_manifest.dart "$@"
        '';

        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            cmake
            ninja
            pkg-config
            clang
          ];

          buildInputs = with pkgs; [
            flutter
            androidSdk
            jdk17
            
            # Linux build dependencies
            gtk3
            glib
            pcre2
            libdatrie
            libthai
            libselinux
            libsepol
            util-linux
            libxkbcommon
            dbus
            at-spi2-core
            libepoxy
            xorg.libXdmcp
            xorg.libXtst
            
            # Requested tools
            sops
            age
            git
          ];

          shellHook = ''
            export ANDROID_SDK_ROOT=${androidSdk}/libexec/android-sdk
            export CHROME_EXECUTABLE=google-chrome-stable
          '';
        };
      });
}
