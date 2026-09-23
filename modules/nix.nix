# Nix hygiene: one nixpkgs (the flake's), and nothing accumulates.
{ config, nixpkgs, ... }:
{
  # `nix shell nixpkgs#foo` resolves to the nixpkgs this flake pins instead of
  # downloading another one.
  nix.registry.nixpkgs.flake = nixpkgs;

  # Weekly: drop Home Manager generations older than two weeks, then collect
  # garbage with pacman's nix.
  systemd.user.services.nix-gc = {
    Unit.Description = "Expire old Home Manager generations and collect Nix garbage";
    Service = {
      Type = "oneshot";
      ExecStart = [
        "${config.home.profileDirectory}/bin/home-manager expire-generations \"-14 days\""
        "/usr/bin/nix-collect-garbage --delete-older-than 14d"
      ];
    };
  };
  systemd.user.timers.nix-gc = {
    Unit.Description = "Weekly Nix garbage collection";
    Timer = {
      OnCalendar = "weekly";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
