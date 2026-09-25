# App launcher hygiene: only entries that open a window stay visible.
# launcher-curate hides the rest (see files/launcher-curate.rules) and is
# re-run whenever installed applications or the rules change.
{ config, ... }:
let
  home = config.home.homeDirectory;
  curate = "${home}/.local/bin/launcher-curate";
in
{
  home.file.".local/bin/launcher-curate" = {
    source = ../files/bin/launcher-curate;
    executable = true;
  };
  xdg.configFile."launcher-curate/rules".source = ../files/launcher-curate.rules;

  systemd.user.services.launcher-curate = {
    Unit.Description = "Hide launcher entries that cannot open a window";
    Service = {
      Type = "oneshot";
      # Debounce: installs and home-manager switches change many files at once.
      ExecStartPre = "/usr/bin/sleep 2";
      ExecStart = curate;
    };
    Install.WantedBy = [ "default.target" ];
  };
  systemd.user.paths.launcher-curate = {
    Unit.Description = "Re-curate launcher entries when applications change";
    Path.PathChanged = [
      "/usr/share/applications"
      "/usr/local/share/applications"
      "${home}/.local/share/applications"
      "${home}/.nix-profile/share/applications"
      "${home}/.config/launcher-curate"
    ];
    Install.WantedBy = [ "default.target" ];
  };
}
