# Emacs/nvim as versioned store text. Packages stay pacman (emacs/neovim).
{ config, ... }:
{
  xdg.configFile = {
    "nvim/init.lua".source = ../files/nvim/init.lua;
    "nvim/lua/plugins.lua".source = ../files/nvim/lua/plugins.lua;
    "nvim/nvim-pack-lock.json".source = ../files/nvim/nvim-pack-lock.json;

    # Emacs runs as a daemon from login, so Super+E (emacsclient -c) opens a
    # frame at once; with no daemon it falls back to a cold start (about
    # 1.5 s of init). The unit ships with pacman's emacs package; this only
    # enables it. A plain unit override would restart the daemon on every
    # change and drop its open buffers.
    "systemd/user/default.target.wants/emacs.service" = {
      source = config.lib.file.mkOutOfStoreSymlink "/usr/lib/systemd/user/emacs.service";
      force = true; # replaces the symlink `systemctl --user enable emacs` made by hand
    };
  };
  home.file = {
    ".emacs.d/init.el".source = ../files/emacs/init.el;
    ".emacs.d/early-init.el".source = ../files/emacs/early-init.el;
    ".emacs.d/lisp/fasm-mode.el".source = ../files/emacs/lisp/fasm-mode.el;
    ".emacs.d/lisp/scratch-magic-polish.el".source = ../files/emacs/lisp/scratch-magic-polish.el;
  };
}
