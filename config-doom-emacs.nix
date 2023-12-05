{ pkgs, config, ... }:
let
  doom-config = ".config/doom";
  prefix = "${config.home.homeDirectory}/projects/mac-dev-setup/doom-emacs";
in {
  home.file = {
    "${doom-config}/init.el".source =
      config.lib.file.mkOutOfStoreSymlink "${prefix}-init.el";
    "${doom-config}/packages.el".source =
      config.lib.file.mkOutOfStoreSymlink "${prefix}-packages.el";
    "${doom-config}/config.el".source =
      config.lib.file.mkOutOfStoreSymlink "${prefix}-config.el";
  };
}
