{
  description = "yuri4n's home, on any machine with Nix";

  inputs = {
    # 26.05 is the last nixpkgs release that supports Intel Macs (x86_64-darwin).
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
    }:
    let
      user = "yuri4n";
      forAll = nixpkgs.lib.genAttrs [
        "x86_64-darwin"
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    {
      homeConfigurations = forAll (
        system:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = { inherit user; };
          modules = [
            ./home.nix
            ./zed.nix
          ];
        }
      );

      # `nix run .` switches to the configuration of the current platform.
      apps = forAll (system: {
        default = {
          type = "app";
          meta.description = "Switch to this home configuration";
          program = "${nixpkgs.legacyPackages.${system}.writeShellScript "switch" ''
            exec ${home-manager.packages.${system}.default}/bin/home-manager \
              switch -b backup --flake ${self}#${system} "$@"
          ''}";
        };
      });

      formatter = forAll (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
    };
}
