# base on https://github.com/tyler-dodge/emacs/blob/tyler-main-emacs-29/default.nix
{ pkgs ? (import <nixpkgs> { }) }:
let
  thread-list = list: start:
    pkgs.lib.lists.foldl (acc: item: (item acc)) start list;

  sdk_root =
    /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk;

  xcrun_path = /usr/bin/xcrun;

  make_impure_sdk = with pkgs;
    { lib_path ? null, include_path ? null, framework_path, }:
    let
      lib_command = pkgs.lib.strings.concatStrings
        (pkgs.lib.optional (lib_path != null) ''
          if ! [ -x ${lib_path} ]; then
            echo Cannot find command ${lib_path}
            exit 1
          fi
          ln -s ${lib_path} $out/lib
        '');

      include_command = pkgs.lib.strings.concatStrings
        (pkgs.lib.optional (lib_path != null) ''
          if ! [ -x ${include_path} ]; then
            echo Cannot find command ${include_path}
            exit 1
          fi
          ln -s ${include_path} $out/include
        '');

      script = ''
        mkdir -p $out/Library/

        ${lib_command}
        ${include_command}
        if ! [ -x ${framework_path} ]; then
          echo Cannot find command ${framework_path}
          exit 1
        fi
        ln -s ${framework_path} $out/Library/Frameworks
      '';
    in runCommandLocal "apple-sdk--impure-darwin" {
      __impureHostDeps = [ lib_path framework_path framework_path ];
      meta = { platforms = lib.platforms.darwin; };
    } script;

  mkImpureDrv = with pkgs;
    name: path:
    let
      script = ''
        if ! [ -x ${path} ]; then
          echo Cannot find command ${path}
          exit 1
        fi

        mkdir -p $out/bin
        ln -s ${path} $out/bin/${name}
      '';
    in runCommandLocal "${name}-impure-darwin" {
      meta = { platforms = lib.platforms.darwin; };
    } script;

  impure_apple_sdk = make_impure_sdk {
    lib_path = sdk_root + "/usr/lib";
    include_path = sdk_root + "/usr/include";
    framework_path = sdk_root + "/System/Library/Frameworks";
  };

  filter_apple_sdk = thread-list [
    (pkgs.lib.lists.filter (it: it != null))
    (pkgs.lib.lists.filter
      (it: !(pkgs.lib.strings.hasInfix "apple-framework" it.name)))
    (pkgs.lib.lists.filter
      (it: !(pkgs.lib.strings.hasInfix "clang-wrapper" it.name)))
  ];

  extra_inputs = [
    pkgs.clang_15
    pkgs.tree-sitter
    pkgs.giflib
    (mkImpureDrv "xcrun" xcrun_path)
    impure_apple_sdk
    pkgs.source-code-pro
    pkgs.libjpeg
    pkgs.libtiff
    pkgs.lcms2
    # emacs 29.1
    pkgs.git
  ];
  emacs29 = pkgs.emacs29.overrideAttrs (prevAttrs: {
    version = "29";

    SDKROOT = impure_apple_sdk;

    CC = pkgs.clang_15;

    preConfigure = ''
      export MACOSX_DEPLOYMENT_TARGET="12.0"
    '';

    # https://nixos.wiki/wiki/Emacs Darwin (macOS)
    patches = (prevAttrs.patches) ++ [
      # Fix OS window role (needed for window managers like yabai)
      (pkgs.fetchpatch {
        url =
          "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/master/patches/emacs-28/fix-window-role.patch";
        hash = "sha256-+z/KfsBm1lvZTZNiMbxzXQGRTjkCFO4QPlEK35upjsE=";
      })
      # Make Emacs aware of OS-level light/dark mode
      (pkgs.fetchpatch {
        url =
          "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/master/patches/emacs-28/system-appearance.patch";
        hash = "sha256-oM6fXdXCWVcBnNrzXmF0ZMdp8j0pzkLE66WteeCutv8=";
      })
      # Use poll instead of select to get file descriptors
      (pkgs.fetchpatch {
        url =
          "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/master/patches/emacs-29/poll.patch";
        sha256 = "sha256-jN9MlD8/ZrnLuP2/HUXXEVVd6A+aRZNYFdZF8ReJGfY=";
      })
      # Enable rounded window with no decoration
      (pkgs.fetchpatch {
        url =
          "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/master/patches/emacs-29/round-undecorated-frame.patch";
        sha256 = "sha256-uYIxNTyfbprx5mCqMNFVrBcLeo+8e21qmBE3lpcnd+4=";
      })
    ];

    configureFlags = prevAttrs.configureFlags
      ++ [ "--with-ns" "--without-libgmp" "--with-tree-sitter" ];

    buildInputs = (filter_apple_sdk prevAttrs.buildInputs) ++ extra_inputs;

    nativeBuildInputs = (filter_apple_sdk prevAttrs.nativeBuildInputs)
      ++ extra_inputs;

    # use source from pkgs.emacs29
    # src = ./.;
  });
in { inherit emacs29; }
