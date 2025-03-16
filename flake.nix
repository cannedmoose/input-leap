{
  description = "Input Leap - Open-source KVM software";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    mini-compile-commands = {
      url = "github:danielbarter/mini_compile_commands";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, mini-compile-commands }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        input-leap-pkg = { withLibei ? true }: pkgs.stdenv.mkDerivation rec {
          pname = "input-leap";
          version = "3.0.2";

          src = ./.;

          nativeBuildInputs = [
            pkgs.pkg-config
            pkgs.cmake
            pkgs.wrapGAppsHook3
            pkgs.qt6Packages.wrapQtAppsHook
            pkgs.qt6.qttools
          ];

          buildInputs = [
            pkgs.curl
            pkgs.qt6.qtbase
            (pkgs.avahi.override { withLibdnssdCompat = true; })
            pkgs.xorg.libX11
            pkgs.xorg.libXext
            pkgs.xorg.libXtst
            pkgs.xorg.libXinerama
            pkgs.xorg.libXrandr
            pkgs.xorg.libXdmcp
            pkgs.xorg.libICE
            pkgs.xorg.libSM
          ] ++ pkgs.lib.optionals withLibei [
            pkgs.libei
            pkgs.libportal
          ];

          cmakeFlags = [
            "-DINPUTLEAP_REVISION=${toString (self.shortRev or self.dirtyShortRev or self.lastModified or "unknown")}"
          ] ++ (pkgs.lib.optional withLibei "-DINPUTLEAP_BUILD_LIBEI=ON");

          dontWrapGApps = true;
          preFixup = ''
            echo "Running preFixup with openssl path: ${pkgs.lib.makeBinPath [ pkgs.openssl ]}"
            qtWrapperArgs+=(
              "''${gappsWrapperArgs[@]}"
                --prefix PATH : "${pkgs.lib.makeBinPath [ pkgs.openssl ]}"
            )
          '';

          /*postFixup = ''
            echo "Running postFixup, substituting desktop file paths"
            substituteInPlace $out/share/applications/io.github.input_leap.InputLeap.desktop \
              --replace "Exec=input-leap" "Exec=$out/bin/input-leap"
          '';*/

          meta = {
            description = "Open-source KVM software";
            longDescription = ''
              Input Leap is software that mimics the functionality of a KVM switch, which historically
              would allow you to use a single keyboard and mouse to control multiple computers by
              physically turning a dial on the box to switch the machine you're controlling at any
              given moment. Input Leap does this in software, allowing you to tell it which machine
              to control by moving your mouse to the edge of the screen, or by using a keypress
              to switch focus to a different system.
            '';
            homepage = "https://github.com/input-leap/input-leap";
            license = pkgs.lib.licenses.gpl2Plus;
            maintainers = with pkgs.lib.maintainers; [
            ];
            platforms = pkgs.lib.platforms.linux;
          };
        };
      in
      {
        packages = {
          default = input-leap-pkg { };
          input-leap = input-leap-pkg { };
          input-leap-no-libei = input-leap-pkg { withLibei = false; };
        };

        /*apps = {
          default = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/input-leap";
          };
        };*/

        # NOTE TO GET WORKING WITH GCC USED:
        # https://discourse.nixos.org/t/get-clangd-to-find-standard-headers-in-nix-shell/11268

        devShells.default = pkgs.mkShell {
          packages = [pkgs.lldb];
          buildInputs = [
            pkgs.cmake
            pkgs.pkg-config
            pkgs.qt6.qtbase
            pkgs.qt6.qttools
            pkgs.curl
            (pkgs.avahi.override { withLibdnssdCompat = true; })
            pkgs.xorg.libX11
            pkgs.xorg.libXext
            pkgs.xorg.libXtst
            pkgs.xorg.libXinerama
            pkgs.xorg.libXrandr
            pkgs.xorg.libXdmcp
            pkgs.xorg.libICE
            pkgs.xorg.libSM
            pkgs.libei
            pkgs.libportal
            pkgs.openssl
            pkgs.clang-tools
          ];

          shellHook = ''
            echo "Input Leap development environment loaded"
            echo "Build dependencies installed"
          '';
        };
      });
}
