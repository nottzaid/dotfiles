# Laptop: Dell Inspiron 5583, Intel UHD 620 (drives the panel) + NVIDIA MX130.
{
  home.username = "muradkant";
  home.homeDirectory = "/home/muradkant";
  dotfiles.host = "laptop";

  dotfiles.noctalia = {
    widget.i3_workspaces.monitor = "eDP-1";
    widget.battery.color = "#94e2d5";
    widget.sep_6.type = "zaid/i3bar:separator";
  };
  dotfiles.noctaliaStatusExtra = [
    "battery"
    "sep_6"
  ];
}
