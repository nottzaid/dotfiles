{ ... }:
{
  home.username = "zaid";
  home.homeDirectory = "/home/zaid";
  home.stateVersion = "26.05";
  targets.genericLinux = {
    enable = true;
    # pacman owns the GPU stack; the Nix GPU shim would pull ~1 GB of Mesa/LLVM.
    gpu.enable = false;
  };
  imports = [
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
}
