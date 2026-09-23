# Nix hygiene: one nixpkgs (the flake's), and nothing accumulates.
{ config, pkgs, nixpkgs, ... }:
{
  # `nix shell nixpkgs#foo` resolves to the nixpkgs this flake pins instead of
  # downloading another one.
  nix.registry.nixpkgs.flake = nixpkgs;

  # Home Manager uses nix.package for its activation tools (nix-build,
  # nix-env, ...) and genericLinux sources its etc/profile.d/nix.sh. Point the
  # tools at pacman's Nix and ship only that script (it has no store
  # references), instead of a second Nix beside pacman's.
  nix.package = pkgs.runCommand "pacman-nix" { } ''
    mkdir -p $out/bin
    for tool in nix nix-build nix-channel nix-collect-garbage nix-env \
      nix-instantiate nix-shell nix-store; do
      ln -s /usr/bin/$tool $out/bin/$tool
    done
    install -Dm644 ${pkgs.nix}/etc/profile.d/nix.sh $out/etc/profile.d/nix.sh
  '';

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
