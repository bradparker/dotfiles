{
  description = "Home Manager configuration of bradparker";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    {
      homeConfigurations = {
        "bradparker@Mac" = home-manager.lib.homeManagerConfiguration rec {
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
        "brad@fedora" = home-manager.lib.homeManagerConfiguration rec {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;

          modules = [
            {
              home.username = "brad";
              home.homeDirectory = "/home/brad";

              targets.genericLinux.enable = true;
              xdg.enable = true;

              home.packages = with pkgs; [
                xclip
                xsel
                signal-desktop
              ];

              programs =  {
                firefox = {
                  enable = true;
                  package = pkgs.firefox;
                  profiles.brad = {
                    id = 0;
                    isDefault = true;
                    settings = {
                      "font.name.monospace.x-western" = "Roboto Mono";
                      "font.name.sans-serif.x-western" = "Roboto";
                      "font.name.serif.x-western" = "serif";
                      "font.size.monospace.x-western" = "16";
                    };
                  };
                };
              };
            }
            ./home.nix
          ];
        };
      };
    };
}
