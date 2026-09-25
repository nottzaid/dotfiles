# What differs between machines. Each hosts/<host>.nix sets these; everything
# else is shared. Per-machine files live under files/hosts/<host>/.
{ lib, ... }:
{
  options.dotfiles = {
    host = lib.mkOption {
      type = lib.types.str;
      description = "Machine name: selects files/hosts/<host>/ (Hyprland host.lua, uwsm env additions).";
    };
    noctalia = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Settings merged over files/noctalia.toml for this machine.";
    };
    noctaliaStatusExtra = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Bar widgets inserted into the status area, just before the clock.";
    };
  };
}
