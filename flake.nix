{
  description = "Home Manager configurations for zaid's machines";
  inputs = {
    # Submodules (components/) are deployed by Home Manager, so the flake needs them.
    self.submodules = true;
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      mkHome =
        host:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit nixpkgs; };
          modules = [
            ./home.nix
            host
          ];
        };
    in
    {
      # One configuration per machine, named after its user.
      homeConfigurations = {
        zaid = mkHome ./hosts/desktop.nix;
        muradkant = mkHome ./hosts/laptop.nix;
      };
    };
}
