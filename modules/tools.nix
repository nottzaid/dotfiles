# Helper scripts, the streaming component, and the few CLI tools pacman does
# not package (everything else is in packages/*.txt).
{ pkgs, ... }:
{
  home.packages = [
    pkgs.exercism
    pkgs.subfinder
  ];
  home.file = {
    ".local/bin/swash-screenshot" = { source = ../files/bin/swash-screenshot; executable = true; };
    ".local/bin/hypr-display-reload" = { source = ../files/bin/hypr-display-reload; executable = true; };
    ".local/bin/workspace-stream" = {
      source = ../components/yt-stream-workspace/bin/workspace-stream;
      executable = true;
    };
    "Pictures/background.jpg".source = ../files/background.jpg;
    "Pictures/lockscreen.jpg".source = ../files/lockscreen.jpg;
  };
}
