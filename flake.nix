{
  description = "Home Manager configuration of bradparker";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    {
      homeConfigurations."bradparker@Mac" = home-manager.lib.homeManagerConfiguration rec {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;

        modules = [
          {
            home.username = "bradparker";
            home.homeDirectory = "/Users/bradparker";

            programs = {
              alacritty = {
                enable = true;
                settings = {
                  shell = {
                    program = "${pkgs.tmux}/bin/tmux";
                    args = [ "attach" ];
                  };
                  window = {
                    decorations = "buttonless";
                    padding = {
                      x = 16;
                      y = 16;
                    };
                  };
                  font = {
                    size = 18;
                    normal = {
                      family = "Fira Code";
                      style = "Regular";
                    };
                    bold = {
                      family = "Fira Code";
                      style = "Bold";
                    };
                    italic = {
                      family = "Fira Code";
                      style = "Italic";
                    };
                  };
                };
              };
            };
          }
          ./home.nix
        ];
      };
    };
}
