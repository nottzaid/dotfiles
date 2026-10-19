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
    ".local/bin/scratch-world" = { source = ../files/bin/scratch-world; executable = true; };
    ".local/bin/gaming-mode" = { source = ../files/bin/gaming-mode; executable = true; };
    ".local/bin/gaming-mode-art" = { source = ../files/bin/gaming-mode-art; executable = true; };
    ".local/bin/gaming-mode-review" = { source = ../files/bin/gaming-mode-review; executable = true; };
    ".config/quickshell/gaming-mode/shell.qml".source = ../files/quickshell/gaming-mode/shell.qml;
    ".local/bin/workspace-stream" = {
      source = ../components/yt-stream-workspace/bin/workspace-stream;
      executable = true;
    };
    "Pictures/background.jpg".source = ../files/background.jpg;
    "Pictures/lockscreen.jpg".source = ../files/lockscreen.jpg;
  };
}
