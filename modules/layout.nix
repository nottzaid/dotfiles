# Home directory layout: tools keep their state under the XDG base
# directories instead of scattering dot-folders across ~, and only the user
# directories that are actually used exist.
{ config, lib, ... }:
let
  home = config.home.homeDirectory;
  data = config.xdg.dataHome;
  cache = config.xdg.cacheHome;
in
{
  xdg.enable = true;

  # genericLinux also lists Ubuntu and snapd paths; this machine has neither.
  xdg.systemDirs.data = lib.mkForce [
    "${config.home.profileDirectory}/share"
    "/usr/local/share"
    "/usr/share"
  ];

  home.sessionVariables = {
    GOPATH = "${data}/go";
    GOMODCACHE = "${cache}/go/mod";
    CARGO_HOME = "${data}/cargo";
    RUSTUP_HOME = "${data}/rustup";
    WINEPREFIX = "${data}/wine";
    DOCKER_CONFIG = "${config.xdg.configHome}/docker";
    NPM_CONFIG_CACHE = "${cache}/npm";
    CUDA_CACHE_PATH = "${cache}/nv";
  };

  # Setting a user directory to $HOME marks it unused, so xdg-user-dirs-update
  # stops recreating Desktop, Music, Public, and Templates at every login.
  xdg.userDirs = {
    enable = true;
    package = null; # pacman's xdg-user-dirs
    createDirectories = false;
    desktop = home;
    documents = "${home}/Documents";
    download = "${home}/Downloads";
    music = home;
    pictures = "${home}/Pictures";
    publicShare = home;
    templates = home;
    videos = "${home}/Videos";
    extraConfig.PROJECTS = "${home}/Projects";
  };
}
