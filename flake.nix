{
  description = "Lorenzo's dotfiles - Nix flake for reproducible system configuration";

  inputs = {
    # Nixpkgs - main package repository
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Home Manager - user environment management
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Darwin (macOS) system configuration
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Flake utilities
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, home-manager, darwin, flake-utils, ... }@inputs:
    let
      # Supported systems
      supportedSystems = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux" ];

      # Helper to generate attributes for each system
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # User configuration
      user = {
        name = "Lorenzo Scaturchio";
        email = "lorenzosca7@protonmail.ch";
        username = "gr8monk3ys";
        github = "gr8monk3ys";
      };

      # Common packages for all systems
      commonPackages = pkgs: with pkgs; [
        # Modern CLI tools (Rust-powered)
        eza           # ls replacement
        bat           # cat replacement
        fd            # find replacement
        ripgrep       # grep replacement
        zoxide        # cd replacement
        delta         # diff replacement
        dust          # du replacement
        procs         # ps replacement
        sd            # sed replacement
        bottom        # htop replacement
        hyperfine     # benchmarking
        tokei         # code stats
        watchexec     # file watching

        # New modern tools
        yazi          # file manager
        jujutsu       # next-gen git (jj)
        zellij        # terminal multiplexer
        navi          # cheatsheets
        broot         # tree navigation
        tealdeer      # tldr client
        gping         # graphical ping
        ouch          # archive tool

        # Shell & terminal
        fzf           # fuzzy finder
        atuin         # shell history
        direnv        # per-dir env
        starship      # prompt (optional)

        # Development
        neovim
        git
        gh            # GitHub CLI
        lazygit       # git TUI

        # Version managers
        mise          # universal version manager

        # Languages (let mise handle specific versions)
        nodejs
        python3
        rustup

        # Build tools
        gnumake
        cmake

        # Shell
        zsh
        zsh-syntax-highlighting
        zsh-autosuggestions

        # Utilities
        stow          # symlink manager
        jq            # JSON processor
        yq            # YAML processor
        curl
        wget
        tree
        htop
        ncdu
      ];

      # macOS-specific packages
      darwinPackages = pkgs: with pkgs; [
        # macOS specific tools
        coreutils
        gnused
        gawk
        findutils
      ];

      # Linux-specific packages
      linuxPackages = pkgs: with pkgs; [
        # Linux specific tools
        xclip
        wl-clipboard
      ];

    in {
      # ========================================================================
      # Home Manager configurations (cross-platform)
      # ========================================================================
      homeConfigurations = {
        # macOS (Apple Silicon)
        "gr8monk3ys@macbook" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.aarch64-darwin;
          extraSpecialArgs = { inherit inputs user; };
          modules = [
            ./nix/home.nix
            {
              home = {
                username = user.username;
                homeDirectory = "/Users/${user.username}";
                stateVersion = "24.05";
                packages = (commonPackages nixpkgs.legacyPackages.aarch64-darwin)
                  ++ (darwinPackages nixpkgs.legacyPackages.aarch64-darwin);
              };
            }
          ];
        };

        # macOS (Intel)
        "gr8monk3ys@macbook-intel" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-darwin;
          extraSpecialArgs = { inherit inputs user; };
          modules = [
            ./nix/home.nix
            {
              home = {
                username = user.username;
                homeDirectory = "/Users/${user.username}";
                stateVersion = "24.05";
                packages = (commonPackages nixpkgs.legacyPackages.x86_64-darwin)
                  ++ (darwinPackages nixpkgs.legacyPackages.x86_64-darwin);
              };
            }
          ];
        };

        # Linux (x86_64)
        "gr8monk3ys@linux" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = { inherit inputs user; };
          modules = [
            ./nix/home.nix
            {
              home = {
                username = user.username;
                homeDirectory = "/home/${user.username}";
                stateVersion = "24.05";
                packages = (commonPackages nixpkgs.legacyPackages.x86_64-linux)
                  ++ (linuxPackages nixpkgs.legacyPackages.x86_64-linux);
              };
            }
          ];
        };

        # Linux (ARM64)
        "gr8monk3ys@linux-arm" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.aarch64-linux;
          extraSpecialArgs = { inherit inputs user; };
          modules = [
            ./nix/home.nix
            {
              home = {
                username = user.username;
                homeDirectory = "/home/${user.username}";
                stateVersion = "24.05";
                packages = (commonPackages nixpkgs.legacyPackages.aarch64-linux)
                  ++ (linuxPackages nixpkgs.legacyPackages.aarch64-linux);
              };
            }
          ];
        };
      };

      # ========================================================================
      # Darwin (macOS) system configurations
      # ========================================================================
      darwinConfigurations = {
        "macbook" = darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = { inherit inputs user; };
          modules = [
            ./nix/darwin.nix
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit inputs user; };
                users.${user.username} = import ./nix/home.nix;
              };
            }
          ];
        };

        "macbook-intel" = darwin.lib.darwinSystem {
          system = "x86_64-darwin";
          specialArgs = { inherit inputs user; };
          modules = [
            ./nix/darwin.nix
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit inputs user; };
                users.${user.username} = import ./nix/home.nix;
              };
            }
          ];
        };
      };

      # ========================================================================
      # Development shells
      # ========================================================================
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.mkShell {
            buildInputs = commonPackages pkgs ++ [
              pkgs.nil           # Nix LSP
              pkgs.nixpkgs-fmt   # Nix formatter
            ];
            shellHook = ''
              echo "Dotfiles development environment"
              echo "Run 'make' to see available commands"
            '';
          };
        }
      );

      # ========================================================================
      # Packages (for nix profile install)
      # ========================================================================
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.writeShellScriptBin "dotfiles-nix" ''
            echo "Lorenzo's Dotfiles - Nix Installation"
            echo ""
            echo "Available commands:"
            echo "  nix run .#switch-home    - Apply Home Manager config"
            echo "  nix run .#switch-darwin  - Apply Darwin config (macOS)"
            echo "  nix develop              - Enter development shell"
          '';

          switch-home = pkgs.writeShellScriptBin "switch-home" ''
            home-manager switch --flake .
          '';

          switch-darwin = pkgs.writeShellScriptBin "switch-darwin" ''
            darwin-rebuild switch --flake .
          '';
        }
      );

      # ========================================================================
      # Formatter
      # ========================================================================
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);
    };
}
