{ config, pkgs, lib, ... }:
let
  catDir = dirName:
    pkgs.lib.pipe dirName [
      builtins.readDir
      (pkgs.lib.filterAttrs (_: value: value == "regular"))
      pkgs.lib.attrNames
      (pkgs.lib.concatMapStrings
        (name: builtins.readFile (dirName + "/${name}")))
      ];

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
in {
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "1password-cli"
  ];

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  home.sessionVariables = {
    NIX_PATH = "nixpkgs=${pkgs.path}";
  };

  home.packages = with pkgs; [
    _1password-cli
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
    fira
    fira-code
    fzf
    ghc
    git
    haskell-language-server
    haskellPackages.ghcid
    haskellPackages.hlint
    heroku
    htop
    hyperfine
    ipcalc
    jq
    libossp_uuid
    lynx
    nix
    nmap
    nodePackages.ts-node
    nodejs
    ormolu
    pgformatter
    ripgrep
    roboto
    roboto-mono
    rufo
    shellcheck
    sl
    tig
    time
    tree
    vulnix
    watch
  ]
  ++ pkgs.lib.attrValues scripts;

  home.file = {
    ".gitignore".text = builtins.readFile ./programs/git/gitignore;
    ".gitconfig".text = builtins.readFile ./programs/git/gitconfig;

    ".editorconfig".text = ''
      root = true

      [*]
      end_of_line = lf
      trim_trailing_whitespace = true
      insert_final_newline = true
      indent_style = space
      indent_size = 2
    '';

    ".ghci".text = builtins.readFile ./programs/ghc/ghci;
  };

  programs = {
    home-manager.enable = true;

    bash = {
      enable = true;
      initExtra = ''
        ${catDir ./programs/bash}

        eval "$(${pkgs.coreutils}/bin/dircolors)"
      '';
    };

    tmux = {
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

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    bat = {
      enable = true;
      config = { theme = "base16"; };
    };

    neovim = {
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
            \   'javascript': ['eslint', 'flow_ls'],
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

            let g:ale_completion_enabled = 0

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
            nmap <C-P> :execute system('git rev-parse --is-inside-work-tree') =~ 'true' ? 'GFiles --cached --others --exclude-standard' : 'Files'<CR>
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
  };
}
