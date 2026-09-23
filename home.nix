{ config, pkgs, ... }:
{
  home.username = "zaid";
  home.homeDirectory = "/home/zaid";
  home.stateVersion = "26.05";
  targets.genericLinux.enable = true;
  imports = [
    ./modules/shell.nix
    ./modules/desktop.nix
    ./modules/editors.nix
    ./modules/tools.nix
    ./modules/launcher.nix
  ];
  # Config-only migration: pacman keeps owning all binaries/drivers.
  home.packages = [ ];
  programs.home-manager.enable = true;
  # Kill the ghost: fish/config.fish.bak.1788613833 was committed slop, not config.
}
