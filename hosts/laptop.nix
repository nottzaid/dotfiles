# Laptop: Dell Inspiron 5583, Intel UHD 620 (drives the panel) + NVIDIA MX130.
{ pkgs, ... }:
{
  home.username = "muradkant";
  home.homeDirectory = "/home/muradkant";
  dotfiles.host = "laptop";

  dotfiles.noctalia = {
    widget.i3_workspaces.monitor = "eDP-1";
    widget.battery.color = "#94e2d5";
    widget.sep_6.type = "zaid/i3bar:separator";
  };
  # Tools pacman lacks (the AUR signal-cli builds Gradle and Rust from source).
  home.packages = [ pkgs.signal-cli ];

  dotfiles.noctaliaStatusExtra = [
    "battery"
    "sep_6"
  ];
}
