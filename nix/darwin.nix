# Darwin (macOS) system configuration
# https://daiderd.com/nix-darwin/manual/index.html

{ config, pkgs, lib, user, ... }:

{
  # ============================================================================
  # Nix settings
  # ============================================================================
  nix = {
    settings = {
      # Enable flakes
      experimental-features = [ "nix-command" "flakes" ];

      # Trusted users
      trusted-users = [ "root" user.username ];

      # Substituters (binary caches)
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];

      # Auto optimize store
      auto-optimise-store = true;
    };

    # Garbage collection
    gc = {
      automatic = true;
      interval = { Weekday = 7; Hour = 3; Minute = 15; };
      options = "--delete-older-than 30d";
    };
  };

  # ============================================================================
  # System packages (available system-wide)
  # ============================================================================
  environment.systemPackages = with pkgs; [
    # Core utilities
    coreutils
    gnused
    gawk
    findutils

    # Development
    git
    gnumake
    cmake
  ];

  # ============================================================================
  # Homebrew integration
  # ============================================================================
  homebrew = {
    enable = true;

    # Uninstall packages not in the config
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };

    # Taps
    taps = [
      "homebrew/services"
      "nikitabobko/tap"      # AeroSpace
      "oven-sh/bun"
    ];

    # CLI tools (prefer nixpkgs when possible)
    brews = [
      # Tools not in nixpkgs or better via Homebrew
      "mas"                   # Mac App Store CLI
    ];

    # GUI applications
    casks = [
      # Terminal
      "ghostty"

      # Browsers
      "firefox"
      "arc"

      # Development
      "vscodium"
      "docker"

      # Window management
      "aerospace"

      # Utilities
      "raycast"
      "keepassxc"
      "rectangle"             # Fallback window manager

      # Media
      "spotify"
      "vlc"

      # Communication
      "discord"
      "slack"

      # Productivity
      "obsidian"
      "notion"
    ];

    # Mac App Store apps (requires mas)
    masApps = {
      # "App Name" = App ID;
      # Find IDs with: mas search "App Name"
    };
  };

  # ============================================================================
  # macOS System Preferences
  # ============================================================================
  system = {
    # Set keyboard repeat rate
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };

    defaults = {
      # Dock settings
      dock = {
        autohide = true;
        autohide-delay = 0.0;
        autohide-time-modifier = 0.4;
        orientation = "bottom";
        show-recents = false;
        tilesize = 48;
        minimize-to-application = true;
        mru-spaces = false;  # Don't rearrange spaces based on most recent use
      };

      # Finder settings
      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        FXDefaultSearchScope = "SCcf";  # Search current folder
        FXEnableExtensionChangeWarning = false;
        FXPreferredViewStyle = "Nlsv";  # List view
        ShowPathbar = true;
        ShowStatusBar = true;
        _FXShowPosixPathInTitle = true;
      };

      # Global settings
      NSGlobalDomain = {
        # Appearance
        AppleInterfaceStyle = "Dark";
        AppleShowAllExtensions = true;

        # Keyboard
        ApplePressAndHoldEnabled = false;  # Enable key repeat
        InitialKeyRepeat = 15;
        KeyRepeat = 2;

        # Mouse/Trackpad
        AppleEnableSwipeNavigateWithScrolls = true;
        "com.apple.swipescrolldirection" = true;  # Natural scrolling

        # Misc
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
        NSDocumentSaveNewDocumentsToCloud = false;
        NSNavPanelExpandedStateForSaveMode = true;
        NSNavPanelExpandedStateForSaveMode2 = true;
        PMPrintingExpandedStateForPrint = true;
        PMPrintingExpandedStateForPrint2 = true;
      };

      # Trackpad
      trackpad = {
        Clicking = true;  # Tap to click
        TrackpadRightClick = true;
        TrackpadThreeFingerDrag = true;
      };

      # Login window
      loginwindow = {
        GuestEnabled = false;
      };

      # Screen capture
      screencapture = {
        location = "~/Pictures/Screenshots";
        type = "png";
        disable-shadow = true;
      };

      # Custom user preferences
      CustomUserPreferences = {
        # Disable disk image verification
        "com.apple.frameworks.diskimages" = {
          skip-verify = true;
          skip-verify-locked = true;
          skip-verify-remote = true;
        };

        # Enable spring loading for directories
        "com.apple.finder" = {
          SpringloaderVelocity = 1;
        };
      };
    };

    # Activation scripts
    activationScripts.postUserActivation.text = ''
      # Restart affected applications
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';
  };

  # ============================================================================
  # Security
  # ============================================================================
  security.pam.enableSudoTouchIdAuth = true;

  # ============================================================================
  # Services
  # ============================================================================
  services = {
    # Nix daemon
    nix-daemon.enable = true;
  };

  # ============================================================================
  # Fonts
  # ============================================================================
  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" "FiraCode" "Hack" ]; })
    font-awesome
    inter
  ];

  # ============================================================================
  # Programs
  # ============================================================================
  programs = {
    # Zsh (system-wide)
    zsh = {
      enable = true;
    };
  };

  # ============================================================================
  # Users
  # ============================================================================
  users.users.${user.username} = {
    home = "/Users/${user.username}";
    shell = pkgs.zsh;
  };

  # State version
  system.stateVersion = 4;
}
