{
  description = "Home Manager configuration of bradparker";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mac-app-util.url = "github:hraban/mac-app-util";
    base-16-shell-source = {
      flake = false;
      url = "github:chriskempson/base16-shell/ce8e1e540367ea83cc3e01eec7b2a11783b3f9e1";
    };
    git-source = {
      flake = false;
      url = "github:git/git/2befe97201e1f3175cce557866c5822793624b5a";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    mac-app-util,
    base-16-shell-source,
    git-source,
    ...
  }:
  let
    base16-shell = {
      home.file = {
        ".config/base16-shell" = {
          source = base-16-shell-source;
        };
      };
    };
    git-completion = {
      home.file = {
        ".local/share/git-completion.bash" = {
          source = "${git-source}/contrib/completion/git-completion.bash";
        };
      };
    };
  in {
      homeConfigurations = {
        "bradparker@Mac.localdomain" = home-manager.lib.homeManagerConfiguration rec {
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
            mac-app-util.homeManagerModules.default
            base16-shell
            git-completion
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
            base16-shell
            git-completion
            ./home.nix
          ];
        };
      };
    };
}
