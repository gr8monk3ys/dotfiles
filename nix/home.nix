# Home Manager configuration
# https://nix-community.github.io/home-manager/options.html

{ config, pkgs, lib, user, ... }:

{
  # ============================================================================
  # Home Manager settings
  # ============================================================================
  programs.home-manager.enable = true;

  # ============================================================================
  # XDG Base Directories
  # ============================================================================
  xdg = {
    enable = true;
    configHome = "${config.home.homeDirectory}/.config";
    dataHome = "${config.home.homeDirectory}/.local/share";
    cacheHome = "${config.home.homeDirectory}/.cache";
    stateHome = "${config.home.homeDirectory}/.local/state";
  };

  # ============================================================================
  # Git Configuration
  # ============================================================================
  programs.git = {
    enable = true;
    userName = user.name;
    userEmail = user.email;

    delta = {
      enable = true;
      options = {
        navigate = true;
        light = false;
        side-by-side = true;
        line-numbers = true;
        syntax-theme = "base16-onedark";
      };
    };

    extraConfig = {
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = true;
      core.editor = "nvim";
      diff.colorMoved = "default";
      merge.conflictstyle = "diff3";
      help.autocorrect = 1;
      github.user = user.github;
    };

    aliases = {
      s = "status -s";
      l = "log --pretty=oneline -n 20 --graph --abbrev-commit";
      d = "diff";
      co = "checkout";
      br = "branch";
      ci = "commit";
      ca = "commit -a";
      amend = "commit --amend --reuse-message=HEAD";
      undo = "reset HEAD~1 --mixed";
      lg = "log --color --decorate --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
    };

    ignores = [
      ".DS_Store"
      "*.swp"
      "*.swo"
      "*~"
      ".direnv/"
      ".envrc"
      "result"
      "result-*"
    ];
  };

  # ============================================================================
  # Jujutsu (jj) - Modern Git alternative
  # ============================================================================
  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        name = user.name;
        email = user.email;
      };
      ui = {
        default-command = "log";
        diff-editor = ":builtin";
        merge-editor = ":builtin";
        pager = "delta";
      };
      git = {
        auto-local-branch = true;
      };
    };
  };

  # ============================================================================
  # Shell - Zsh
  # ============================================================================
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 50000;
      save = 50000;
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
    };

    shellAliases = {
      # Navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";

      # Modern replacements
      ls = "eza --icons --group-directories-first";
      l = "eza -l --icons --git --group-directories-first";
      la = "eza -la --icons --git --group-directories-first";
      ll = "eza -la --icons --git --group-directories-first";
      lt = "eza --tree --icons --git -L 2";
      tree = "eza --tree --icons";

      cat = "bat --paging=never";
      grep = "rg";
      find = "fd";
      du = "dust";
      ps = "procs";
      top = "btm";
      htop = "btm";
      diff = "delta";

      # Git
      g = "git";
      gs = "git status -s";
      gd = "git diff";
      gl = "git log --oneline -20";
      gp = "git pull";
      gP = "git push";

      # Jujutsu
      j = "jj";
      js = "jj status";
      jl = "jj log";
      jd = "jj diff";

      # Editors
      vim = "nvim";
      v = "nvim";

      # File manager
      y = "yazi";

      # Quick edits
      dots = "cd ~/.dotfiles";
      zshrc = "\${EDITOR:-nvim} ~/.config/zsh/.zshrc";

      # Nix
      nrs = "darwin-rebuild switch --flake ~/.dotfiles";
      nhs = "home-manager switch --flake ~/.dotfiles";
      nfu = "nix flake update";
    };

    initExtra = ''
      # Powerlevel10k instant prompt
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi

      # Load p10k config if exists
      [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

      # FZF integration
      eval "$(fzf --zsh)"

      # Zoxide (smart cd)
      eval "$(zoxide init --cmd cd zsh)"

      # Atuin (shell history)
      if command -v atuin &> /dev/null; then
        eval "$(atuin init zsh)"
      fi

      # Direnv
      if command -v direnv &> /dev/null; then
        eval "$(direnv hook zsh)"
      fi

      # Mise (version manager)
      if command -v mise &> /dev/null; then
        eval "$(mise activate zsh)"
      fi

      # Yazi shell wrapper (cd on exit)
      function y() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
        yazi "$@" --cwd-file="$tmp"
        if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
          builtin cd -- "$cwd"
        fi
        rm -f -- "$tmp"
      }
    '';
  };

  # ============================================================================
  # FZF
  # ============================================================================
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
      "--inline-info"
    ];
  };

  # ============================================================================
  # Zoxide
  # ============================================================================
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [ "--cmd" "cd" ];
  };

  # ============================================================================
  # Atuin (shell history)
  # ============================================================================
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      auto_sync = false;  # Enable if you want cloud sync
      sync_frequency = "5m";
      search_mode = "fuzzy";
      filter_mode = "global";
      style = "compact";
    };
  };

  # ============================================================================
  # Direnv
  # ============================================================================
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # ============================================================================
  # Bat (cat replacement)
  # ============================================================================
  programs.bat = {
    enable = true;
    config = {
      theme = "base16-onedark";
      style = "numbers,changes,header";
    };
  };

  # ============================================================================
  # Eza (ls replacement)
  # ============================================================================
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    icons = "auto";
    git = true;
  };

  # ============================================================================
  # Neovim
  # ============================================================================
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    # Configuration is managed via dotfiles symlinks
  };

  # ============================================================================
  # Starship prompt — the binary comes from the Brewfile (macOS); prompt init
  # lives in the stowed .config/zsh/.zshrc (with p10k fallback). Do NOT enable
  # programs.starship here: enableZshIntegration would double-init the prompt.
  # ============================================================================

  # ============================================================================
  # GPG
  # ============================================================================
  programs.gpg = {
    enable = true;
  };

  # ============================================================================
  # SSH
  # ============================================================================
  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
  };
}
