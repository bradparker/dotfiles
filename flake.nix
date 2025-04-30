{
  description = "Home Manager configuration of bradparker";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mac-app-util = {
      url = "github:hraban/mac-app-util";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    base16-shell-source = {
      flake = false;
      url = "github:chriskempson/base16-shell/ce8e1e540367ea83cc3e01eec7b2a11783b3f9e1";
    };
    base16-fzf-source = {
      flake = false;
      url = "github:fnune/base16-fzf/ef4c386689f18bdc754a830a8e66bc2d46d515a";
    };

    git-source = {
      flake = false;
      url = "github:git/git/2befe97201e1f3175cce557866c5822793624b5a";
    };

    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    mac-app-util,
    base16-shell-source,
    base16-fzf-source,
    git-source,
    nixgl,
    ...
  }:
  let
    base16 = {
      home.file = {
        ".config/base16-shell" = {
          source = base16-shell-source;
        };
      };
      programs = {
        bash = {
          initExtra = ''
            if [ ! -z $BASE16_THEME ]; then
              source ${base16-fzf-source}/bash/base16-$BASE16_THEME.config
            fi
          '';
        };
      };
    };
    git-completion = {
      programs = {
        bash = {
          initExtra = ''
            . ${git-source}/contrib/completion/git-completion.bash

            # FIXME: this string is appended, not prepended, to bashrc.
            __git_complete g _git
          '';
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
                    terminal = {
                      shell = {
                        program = "${pkgs.tmux}/bin/tmux";
                        args = [ "attach" ];
                      };
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
            base16
            git-completion

            ./home.nix
          ];
        };
        "brad@fedora" = home-manager.lib.homeManagerConfiguration rec {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;

          modules = [
            (
              {config, ...}: {
                home.username = "brad";
                home.homeDirectory = "/home/brad";

                targets.genericLinux.enable = true;
                xdg.enable = true;

                home.packages = with pkgs; [
                  xclip
                  xsel
                  signal-desktop
                  (config.lib.nixGL.wrap zotero)
                  picard
                ];

                nixGL.packages = nixgl.packages;
                nixGL.defaultWrapper = "mesa";
                nixGL.installScripts = [ "mesa" ];

                programs =  {
                  firefox = {
                    enable = true;
                    package = config.lib.nixGL.wrap pkgs.firefox;
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
            )
            {
              programs.bash.initExtra = ''
                export LOCALE_ARCHIVE=/usr/lib/locale/locale-archive
              '';
            }
            base16
            git-completion

            ./home.nix
          ];
        };
      };
    };
}
