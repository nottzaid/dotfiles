{ pkgs, ... }:
{
  # Identity and machine differences: hosts/<host>.nix.
  home.stateVersion = "26.05";
  targets.genericLinux = {
    enable = true;
    # pacman owns the GPU stack; the Nix GPU shim would pull ~1 GB of Mesa/LLVM.
    gpu.enable = false;
  };
  # Locales for Nix-built programs: UTF-8 only (3 MB instead of 222 MB).
  i18n.glibcLocales = pkgs.glibcLocalesUtf8;
  imports = [
    ./modules/host.nix
    ./modules/shell.nix
    ./modules/desktop.nix
    ./modules/editors.nix
    ./modules/tools.nix
    ./modules/launcher.nix
    ./modules/layout.nix
    ./modules/nix.nix
  ];
  # Ownership: pacman owns binaries, drivers, and the GPU stack. Home Manager
  # owns configuration, plus the few CLI tools pacman lacks (modules/tools.nix).
  programs.home-manager.enable = true;
  # No desktop notification about Home Manager news on every switch.
  news.display = "silent";
}
