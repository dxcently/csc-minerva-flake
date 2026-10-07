{
  description = "Minerva Flake — the CSC public server flake: a minimal dxflake-shaped tree composed with habit.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    habit = {
      url = "github:dxcently/habit";
      inputs.nixpkgs.follows = "nixpkgs"; # habit's nixpkgs only feeds its own checks
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      habit,
      ...
    }@inputs:
    let
      inherit (nixpkgs) lib;
      system = "x86_64-linux";

      # habit (github:dxcently/habit): selection is resolved before any NixOS module graph exists.
      composition = habit.lib.composition { inherit lib; };

      # Hosts live in hosts/<name>/default.nix. This tree ships ONLY the
      # example: real machines are records in a private overlay flake that
      # consumes this one, so addresses, keys and tokens never land here.
      hostNames = [ "example-edge" ];

      hosts = lib.genAttrs hostNames (
        name:
        composition.mkNixosHost {
          inherit nixpkgs system;
          hostName = name;
          knownHosts = hostNames;
          registry = import ./modules;
          hostModules = [ ./hosts/${name} ];
          nucleus = ./modules/nucleus;
          homeManagerModule = home-manager.nixosModules.home-manager;
          specialArgs = { inherit inputs; };
        }
      );
    in
    {
      nixosConfigurations = lib.mapAttrs (_: h: h.system) hosts;

      # What each host actually resolved; `nix eval --json .#inventory.<host>`
      # is the review surface.
      # Proxmox VMA images: `nix build .#images.<host>`, then `qmrestore`.
      images = lib.mapAttrs (_: c: c.config.system.build.VMA) self.nixosConfigurations;

      inventory = lib.mapAttrs (_: h: h.inventory) hosts;

      # The seam a private overlay flake builds on.
      lib.composition = composition;
      registry = import ./modules;
    };
}
