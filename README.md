# What is this

A almost reproducible nix build for Emacs on MacOS

## requirement

homebrew

homebrew is used to install `fontconfig` and `font-symbols-only-nerd-font`

## pkg-emacs29.nix
this will compile emacs29 on mac using [tyler-dodge's nix config](https://tdodge.consulting/blog/living-the-emacs-nix-build-dream) so that `nix-darwin` can manage emacs instead of using homebrew. Read the post for more details.

However, the original nix file is for compiling author's fork of emacs, which he add optimization for [enhancing EShell performance](https://tdodge.consulting/blog/eshell/background-output-thread), and it is based on emacs `29.0.60`.

this modified nix config change it to use `pkgs.emacs29` source, which is emacs version `29.1` required by `doom-emacs`.

## pkg-doom-emacs.nix
this will install dependencies for `doom-emacs`

- pkgs.coreutils, copy GNU ls as `gls`
- pkgs.pandoc, for :lang markdown Markdown processing
- pkgs.shellcheck, for :lang sh Shell script linting

and install `doom-emacs` to `~/.config/emacs` if `~/.config/doom` does not exist.



## config-doom-emacs.nix
Optionally you can add `./config-doom-emacs.nix` to symbol link your doom-emacs config files to

- `$HOME/projects/mac-dev-setup/doom-emacs-init.el`
- `$HOME/projects/mac-dev-setup/doom-emacs-packages.el`
- `$HOME/projects/mac-dev-setup/doom-emacs-config.el`

modify it to your need.


# Usage Example

If you are using `home-manager`, in your `home.nix` file

``` nix
{ config, pkgs, ... }:
let
  my-emacs29 = import ./pkgs-emacs29.nix { inherit pkgs; };
  my-doom-emacs = import ./pkgs-doom-emacs.nix { inherit pkgs; };
in {
  home.packages = with pkgs; [
    my-emacs29.emacs29
    my-doom-emacs
  ];

  # optional
  imports = [ ./config-doom-emacs.nix ];

}
```

or if you are not using `home-manager`, to install emacs system-wide, in your `configuration.nix`

``` nix
{ config, pkgs, ... }:
{
  environment.systemPackages = [
    my-emacs29.emacs29
    my-doom-emacs
  ]
}
```
