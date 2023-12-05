{ pkgs, ... }:

pkgs.stdenv.mkDerivation {
  name = "my-doom-emacs";

  buildInputs = [
    pkgs.git
    (pkgs.ripgrep.override { withPCRE2 = true; })
    # missing dependencies
    pkgs.coreutils # For GNU ls used by dired
    pkgs.pandoc # :lang markdown Markdown compiler
    pkgs.shellcheck # :lang sh Shell script linting

  ];

  # As the package doesn't build anything from source, we don't need the configure, build, and install phases.
  # We override these phases as no-ops to create a wrapper package that simply brings its buildInputs into scope.
  unpackPhase = "true";
  configurePhase = "true";
  buildPhase = "true";
  installPhase = ''
    mkdir -p $out/bin
    # Create symbolic links to binaries or copy any necessary assets to the output directory, if needed.
    ln -s ${pkgs.coreutils}/bin/ls $out/bin/gls
    ln -s ${pkgs.pandoc}/bin/pandoc $out/bin/pandoc
    ln -s ${pkgs.shellcheck}/bin/shellcheck $out/bin/shellcheck
  '';

  postInstall = ''
    if [[ ! -d $HOME/.config/doom/ ]]; then
      git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs
      # take a long time to git clone packages
      $HOME/.config/emacs/bin/doom install

      # dependencies are already specified in Brewfile list here for clarity
      brew install fontconfig
      brww install --cask font-symbols-only-nerd-font
    fi
  '';

  meta = { description = "A wrapper for configurating doom-emacs"; };
}
