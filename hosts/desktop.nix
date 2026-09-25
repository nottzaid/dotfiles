# Desktop: ASUS B85M, NVIDIA GTX 1060; a 24" HDMI monitor plus a 4K TV.
{
  home.username = "zaid";
  home.homeDirectory = "/home/zaid";
  dotfiles.host = "desktop";

  # One workspace-button widget per screen: Noctalia 5.1 does not tell plugin
  # widgets which output they are on, so each bar's instance is told.
  dotfiles.noctalia = {
    widget.i3_workspaces.monitor = "HDMI-A-1";
    widget.i3_workspaces_big = {
      type = "zaid/i3bar:workspaces";
      monitor = "HDMI-A-2";
      color = "#00000000";
    };
    bar.default.monitor.big = {
      match = "HDMI-A-2";
      start = [
        "i3_workspaces_big"
        "spacer_1"
        "active_window"
      ];
    };
  };

  home.file.".local/bin/hypr-display-reload" = {
    source = ../files/bin/hypr-display-reload;
    executable = true;
  };
}
