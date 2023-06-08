{ pkgs, lib, config, ... }:
let
  sources = import ./nix/sources.nix;

  ale = pkgs.vimUtils.buildVimPluginFrom2Nix {
    pname = "ale";
    version = "2020-11-22";
    src = sources.ale;
    meta.homepage = "https://github.com/dense-analysis/ale/";
  };

  catDir = dirName:
    pkgs.lib.pipe dirName [
      builtins.readDir
      (pkgs.lib.filterAttrs (_: value: value == "regular"))
      pkgs.lib.attrNames
      (pkgs.lib.concatMapStrings
        (name: builtins.readFile (dirName + "/${name}")))
    ];

  rufo = pkgs.callPackage ({ buildRubyGem, ruby }:
    buildRubyGem rec {
      inherit ruby;
      gemName = "rufo";
      version = "0.12.0";
      source.sha256 = "0nwasskcm0nrf7f52019x4fvxa5zckj4fcvf4cdl0qflrcwb1l9f";
    }) { };

  clone = { runtimeShell, writeScriptBin }:
    writeScriptBin "clone" ''
      #!${runtimeShell}

      set -xeo pipefail

      repo=$1
      directory=$HOME/Code/$(dirname $repo | cut -d ':' -f 2)
      name=$(basename $repo | sed 's/\.git$//')
      mkdir -p $directory
      git clone $repo $directory/$name
    '';

  cbcopy = { runtimeShell, writeScriptBin }:
    writeScriptBin "cbcopy" ''
      #!${runtimeShell}

      if [ -x "$(command -v xclip)" ]; then
        xclip -selection clipboard $@
      fi

      if [ -x "$(command -v pbcopy)" ]; then
        pbcopy $@
      fi
    '';

  cbpaste = { runtimeShell, writeScriptBin }:
    writeScriptBin "cbpaste" ''
      #!${runtimeShell}

      if [ -x "$(command -v xclip)" ]; then
        xclip -selection clipboard -o $@
      fi

      if [ -x "$(command -v pbpaste)" ]; then
        pbpaste $@
      fi
    '';

  git-wipped = { runtimeShell, writeScriptBin }:
    writeScriptBin "git-wipped" ''
      #!${runtimeShell}

      set -e

      last_commit_message=$(git log -n 1 --format=format:%s)

      if [[ ! $last_commit_message == "[WIP]"* ]];
      then
        echo "Last commit not a [WIP]: $last_commit_message" 1>&2
        exit 1
      fi
    '';

  git-wip = { runtimeShell, writeScriptBin }:
    writeScriptBin "git-wip" ''
      #!${runtimeShell}

      set -e

      git add -A
      git commit -m "[WIP]"
    '';

  git-unwip = { runtimeShell, writeScriptBin, git-wipped }:
    writeScriptBin "git-unwip" ''
      #!${runtimeShell}

      set -eo pipefail

      ${git-wipped}/bin/git-wipped && git reset HEAD~
    '';

  git-amend-wip = { runtimeShell, writeScriptBin, git-wipped }:
    writeScriptBin "git-amend-wip" ''
      #!${runtimeShell}

      set -eo pipefail

      ${git-wipped}/bin/git-wipped && \
        git add -A && \
        git commit --amend --no-edit
    '';

  git-fixup = { runtimeShell, writeScriptBin, git-wip, git-unwip }:
    writeScriptBin "git-fixup" ''
      #!${runtimeShell}

      set -eo pipefail

      path=$1
      last_commit_to_path=$(git log -n 1 --format=format:%H -- $path)

      git add $path -p
      git commit --fixup=$last_commit_to_path

      status=$(git status --porcelain 2> /dev/null)

      if [[ "$status" != "" ]]; then
        ${git-wip}/bin/git-wip
        git rebase --interactive --autosquash $last_commit_to_path~
        ${git-unwip}/bin/git-unwip
      else
        git rebase --interactive --autosquash $last_commit_to_path~
      fi
    '';

  git-trim = { runtimeShell, writeScriptBin, ripgrep }:
    writeScriptBin "git-trim" ''
      #!${runtimeShell}

      set -eo pipefail

      git branch --merged | ${ripgrep}/bin/rg -v '^\*|master' | xargs git branch -d
    '';

  scripts = {
    cbcopy = pkgs.callPackage cbcopy {};
    cbpaste = pkgs.callPackage cbpaste {};

    clone = pkgs.callPackage clone { };
    git-wipped = pkgs.callPackage git-wipped { };
    git-wip = pkgs.callPackage git-wip { };
    git-unwip = pkgs.callPackage git-unwip { git-wipped = scripts.git-wipped; };
    git-amend-wip =
      pkgs.callPackage git-amend-wip { git-wipped = scripts.git-wipped; };
    git-fixup = pkgs.callPackage git-fixup {
      git-wip = scripts.git-wip;
      git-unwip = scripts.git-unwip;
    };
    git-trim = pkgs.callPackage git-trim { };
  };

  maiwar = pkgs.callPackage
    (import (builtins.fetchTarball "https://github.com/bradparker/maiwar/archive/d4f6d8307dbf311fced042d3491a3c2b3f263fe2.tar.gz"))
    {};
in rec {
  imports = [
    ./modules/roboto-fonts.nix
    ./modules/fira-fonts.nix
    ./modules/firefox-with-desktop-entry.nix
    ./modules/signal-desktop-with-desktop-entry.nix
  ];

  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";

  home.stateVersion = "20.09";

  nixpkgs.config = {
    android_sdk.accept_license = true;
  };

  programs.bash = {
    enable = true;
    sessionVariables = { NIX_PATH = "nixpkgs=${sources.nixpkgs}"; };
    initExtra = ''
      ${catDir ./programs/bash}

      eval "$(${pkgs.coreutils}/bin/dircolors)"

      if [ ! -z $BASE16_THEME ]; then
        source ${
          builtins.fetchTarball {
            url =
              "https://github.com/fnune/base16-fzf/archive/ef4c386689f18bdc754a830a8e66bc2d46d515ae.tar.gz";
            sha256 = "1hcr9sq3bxnin2b1pn9dzw39ddxsx1a0fr075l62yn9203fvq0hq";
          }
        }/bash/base16-$BASE16_THEME.config
      fi
    '' + pkgs.lib.optionalString pkgs.stdenv.isLinux ''
      export LOCALE_ARCHIVE=/usr/lib/locale/locale-archive
    '';
  };

  programs.tmux = {
    enable = true;
    escapeTime = 0;
    extraConfig = let
      shellPackage = pkgs.bashInteractive;
      defaultCommand = if pkgs.stdenv.isDarwin then
        "exec ${pkgs.reattach-to-user-namespace}/bin/reattach-to-user-namespace -l ${shellPackage}/bin/bash"
      else
        "exec ${shellPackage}/bin/bash";
    in ''
      set-option -g default-command '${defaultCommand}'

      ${builtins.readFile ./programs/tmux/tmux.conf}
    '';
    newSession = true;
    package = pkgs.tmux;
    plugins = [ ];
    terminal = "screen-256color";
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.alacritty = {
    enable = pkgs.stdenv.isDarwin;
    settings = {
      shell = {
        program = "${programs.tmux.package}/bin/tmux";
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

  programs.firefox-with-desktop-entry = {
    enable = pkgs.stdenv.isLinux;
  };

  programs.signal-desktop-with-desktop-entry = {
    enable = pkgs.stdenv.isLinux;
  };

  fira-fonts.enable = true;

  roboto-fonts.enable = true;

  programs.bat = {
    enable = true;
    config = { theme = "base16"; };
  };

  programs.neovim = {
    enable = true;
    viAlias = false;
    vimAlias = true;
    vimdiffAlias = true;
    withNodeJs = false;
    withRuby = false;
    withPython3 = false;
    extraConfig = ''
      ${builtins.readFile ./programs/vim/vimrc}

      set nohidden

      augroup neovim_terminal
          autocmd!
          " Disables number lines on terminal buffers
          autocmd TermOpen * :setlocal nonumber norelativenumber
      augroup END
    '';
    plugins = with pkgs.vimPlugins; [
      {
        plugin = ale;
        config = ''
          let g:ale_linters = {
          \   'haskell': ['hlint', 'hls'],
          \   'javascript': ['eslint'],
          \   'racket': ['raco'],
          \   'ruby': ['rubocop'],
          \   'eruby': ['erblint'],
          \}

          let g:ale_fixers = {
          \   'elm': ['format'],
          \   'haskell': ['ormolu'],
          \   'javascript': ['prettier'],
          \   'javascriptreact': ['prettier'],
          \   'ruby': ['rubocop'],
          \   'typescript': ['prettier'],
          \   'typescriptreact': ['prettier'],
          \}

          let g:ale_completion_enabled = 1

          let g:ale_fix_on_save = 1

          let g:ale_floating_preview = 1
          let g:ale_detail_to_floating_preview = 1
          let g:ale_hover_to_floating_preview = 1
        '';
      }
      {
        plugin = base16-vim;
        config = ''
          if filereadable(expand("~/.vimrc_background"))
            let base16colorspace=256
            source ~/.vimrc_background
          endif
        '';
      }
      editorconfig-vim
      fugitive
      {
        plugin = fzf-vim;
        config = ''
          nmap <C-P> :execute system('git rev-parse --is-inside-work-tree') =~ 'true' ? 'GFiles' : 'Files'<CR>
        '';
      }
      fzfWrapper
      nerdtree
      repeat
      vim-abolish
      vim-commentary
      vim-gitgutter
      vim-multiple-cursors
      vim-polyglot
      vim-sensible
      vim-surround
      {
        plugin = vim-test;
        config = ''
          let test#strategy = "neovim"
        '';
      }
    ];
  };

  home.file.".gitignore".text = builtins.readFile ./programs/git/gitignore;
  home.file.".gitconfig".text = builtins.readFile ./programs/git/gitconfig;

  home.file.".config/base16-shell" = {
    source = builtins.fetchTarball {
      url =
        "https://github.com/chriskempson/base16-shell/archive/ce8e1e540367ea83cc3e01eec7b2a11783b3f9e1.tar.gz";
      sha256 = "1yj36k64zz65lxh28bb5rb5skwlinixxz6qwkwaf845ajvm45j1q";
    };
  };

  home.file.".local/share/git-completion.bash" = {
    source = "${
        builtins.fetchTarball {
          url =
            "https://github.com/git/git/archive/2befe97201e1f3175cce557866c5822793624b5a.tar.gz";
          sha256 = "1mz0arnnd715jl891yg8hjplkm4hgn7pxhwfva5lbda801nps2r7";
        }
      }/contrib/completion/git-completion.bash";
  };

  home.file.".editorconfig".text = ''
    root = true

    [*]
    end_of_line = lf
    trim_trailing_whitespace = true
    insert_final_newline = true
    indent_style = space
    indent_size = 2
  '';

  home.file.".ghci".text = builtins.readFile ./programs/ghc/ghci;

  home.packages = with pkgs;
    [
      awscli2
      bash-completion
      bashInteractive
      cabal-install
      colima
      coreutils
      dnsutils
      docker
      dua
      emv
      entr
      fd
      fzf
      ghc
      git
      haskell-language-server
      haskellPackages.ghcid
      haskellPackages.hlint
      htop
      hyperfine
      ipcalc
      jq
      libossp_uuid
      lynx
      maiwar
      nmap
      nodejs-16_x
      ormolu
      pgformatter
      ripgrep
      rufo
      shellcheck
      sl
      tig
      time
      tree
      vulnix
      watch
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [ xclip xsel ]
    ++ pkgs.lib.attrValues scripts;
}
