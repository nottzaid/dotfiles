# Earshot: the phone's microphone as a PipeWire mic (~/Projects/earshot).
# earshotd hosts the ROC receiver and the phone's control channel for the
# whole session; on a machine without the project checked out it stays off.
{ config, ... }:
let
  daemon = "${config.home.homeDirectory}/Projects/earshot/pc/earshotd";
in
{
  systemd.user.services.earshotd = {
    Unit = {
      Description = "Earshot phone microphone receiver";
      After = [ "pipewire.service" "pipewire-pulse.service" ];
      Wants = [ "pipewire.service" "pipewire-pulse.service" ];
      ConditionPathExists = daemon;
    };
    Service = {
      ExecStart = daemon;
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
