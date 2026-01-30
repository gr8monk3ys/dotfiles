DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
OS := $(shell bin/platform detect)
HOMEBREW_PREFIX := $(shell bin/platform select /opt/homebrew /usr/local "bin/platform is-arm64")
export N_PREFIX = $(HOME)/.n
PATH := $(HOMEBREW_PREFIX)/bin:$(DOTFILES_DIR)/bin:$(N_PREFIX)/bin:$(PATH)
SHELL := env PATH=$(PATH) /bin/bash
SHELLS := /private/etc/shells
BIN := $(HOMEBREW_PREFIX)/bin
export XDG_CONFIG_HOME = $(HOME)/.config
export STOW_DIR = $(DOTFILES_DIR)
export ACCEPT_EULA=Y

.PHONY: all macos arch link unlink link-dry-run sudo test doctor update backup \
        backup-compress backup-cleanup clean restore brew-update brew-cleanup \
        brew bash git npm packages-macos packages-arch core-macos core-arch \
        stow-arch stow-macos cask-apps vscode-extensions node-packages \
        rust-packages duti bun pacman-packages brew-packages secrets-init \
        secrets-status template-list nix nix-darwin nix-home nix-update help \
        cli cli-install

all: $(OS)

macos: sudo core-macos packages-macos link duti bun

arch: core-arch packages-arch link

core-macos: brew bash git npm

core-arch:
	pacman -Syu --noconfirm

stow-arch: core-arch
	bin/platform has stow || pacman -S --noconfirm stow

stow-macos: brew
	bin/platform has stow || brew install stow

sudo:
ifndef GITHUB_ACTION
	sudo -v
	while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
endif

link: stow-$(OS)
	@echo "Linking dotfiles..."
	mkdir -p "$(XDG_CONFIG_HOME)"
	# Backup existing .zshenv if it exists and is not a symlink
	if [ -f $(HOME)/.zshenv -a ! -h $(HOME)/.zshenv ]; then \
		mv -v $(HOME)/.zshenv $(HOME)/.zshenv.bak; \
	fi
	# Link .zshenv to home directory
	ln -sf $(DOTFILES_DIR)/.zshenv $(HOME)/.zshenv
	# Link .config directory contents
	stow -t "$(XDG_CONFIG_HOME)" .config
	mkdir -p $(HOME)/.local/runtime
	chmod 700 $(HOME)/.local/runtime
	@echo "Dotfiles linked successfully!"

unlink: stow-$(OS)
	@echo "Unlinking dotfiles..."
	stow --delete -t "$(XDG_CONFIG_HOME)" .config
	# Remove .zshenv symlink
	rm -f $(HOME)/.zshenv
	# Restore backup if it exists
	if [ -f $(HOME)/.zshenv.bak ]; then \
		mv -v $(HOME)/.zshenv.bak $(HOME)/.zshenv; \
	fi
	@echo "Dotfiles unlinked successfully!"

brew:
	is-executable brew || curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash

bash: brew
ifdef GITHUB_ACTION
	if ! grep -q bash $(SHELLS); then \
		brew install bash bash-completion@2 pcre && \
		echo $(shell which bash) | sudo tee -a $(SHELLS) && \
		sudo chsh -s $(shell which bash); \
	fi
else
	if ! grep -q bash $(SHELLS); then \
		brew install bash bash-completion@2 pcre && \
		echo $(shell which bash) | sudo tee -a $(SHELLS) && \
		chsh -s $(shell which bash); \
	fi
endif

git: brew
	brew install git git-extras

npm: brew-packages
	n install lts

packages-macos: brew-packages cask-apps node-packages rust-packages

packages-arch: pacman-packages

pacman-packages:
	pacman -S --noconfirm - < $(DOTFILES_DIR)/install/pacmanfile

brew-packages: brew
	brew bundle --file=$(DOTFILES_DIR)/install/Brewfile || true

cask-apps: brew
	brew bundle --file=$(DOTFILES_DIR)/install/Caskfile || true

vscode-extensions: cask-apps
	@if command -v codium >/dev/null 2>&1; then \
		echo "Installing extensions with VSCodium..."; \
		while IFS= read -r ext || [[ -n "$$ext" ]]; do \
			[[ -z "$$ext" || "$$ext" =~ ^# ]] && continue; \
			codium --install-extension "$$ext" || true; \
		done < install/Codefile; \
	elif command -v code >/dev/null 2>&1; then \
		echo "Installing extensions with VS Code..."; \
		while IFS= read -r ext || [[ -n "$$ext" ]]; do \
			[[ -z "$$ext" || "$$ext" =~ ^# ]] && continue; \
			code --install-extension "$$ext" || true; \
		done < install/Codefile; \
	else \
		echo "⚠️  Neither code nor codium found. Skipping extension installation."; \
	fi

node-packages: npm
	$(N_PREFIX)/bin/npm install --force --location global $(shell cat install/npmfile)

rust-packages: brew-packages
	cargo install $(shell cat install/Rustfile)

duti:
	@if command -v duti >/dev/null 2>&1; then \
		echo "Setting default applications with duti..."; \
		duti -v $(DOTFILES_DIR)/install/duti; \
	else \
		echo "⚠️  duti not installed. Skipping default application setup."; \
		echo "   Install with: brew install duti"; \
	fi

bun:
	@if command -v bun >/dev/null 2>&1; then \
		echo "✓ Bun already installed"; \
	else \
		echo "Installing Bun..."; \
		curl -fsSL https://bun.sh/install | bash; \
	fi

test:
	bats test

doctor:
	@bin/dotfiles-doctor

update:
	@bin/dotfiles-update

backup:
	@bin/dotfiles-backup

backup-compress:
	@bin/dotfiles-backup --compress

backup-cleanup:
	@bin/dotfiles-backup --cleanup

clean:
	@echo "Cleaning broken symlinks..."
	@find "$(HOME)/.config" -xtype l -delete 2>/dev/null || true
	@if [ -h "$(HOME)/.zshenv" ] && [ ! -e "$(HOME)/.zshenv" ]; then \
		rm -f "$(HOME)/.zshenv"; \
		echo "Removed broken .zshenv symlink"; \
	fi
	@echo "✓ Cleanup complete"

restore:
	@if [ -f "$(HOME)/.zshenv.bak" ]; then \
		mv "$(HOME)/.zshenv.bak" "$(HOME)/.zshenv"; \
		echo "✓ Restored .zshenv from backup"; \
	else \
		echo "No .zshenv backup found"; \
	fi

brew-update:
	@echo "Updating Homebrew..."
	@brew update && brew upgrade
	@echo "✓ Homebrew updated"

brew-cleanup:
	@echo "Cleaning up Homebrew..."
	@brew cleanup
	@brew bundle cleanup --force
	@echo "✓ Homebrew cleanup complete"

## Dry-run: Show what symlinks would be created without making changes
link-dry-run: stow-$(OS)
	@echo "Dry run - the following symlinks would be created:"
	@echo ""
	@echo "==> .zshenv symlink:"
	@if [ -f "$(HOME)/.zshenv" -a ! -h "$(HOME)/.zshenv" ]; then \
		echo "    Would backup: $(HOME)/.zshenv -> $(HOME)/.zshenv.bak"; \
	fi
	@echo "    Would create: $(HOME)/.zshenv -> $(DOTFILES_DIR)/.zshenv"
	@echo ""
	@echo "==> .config symlinks (via stow):"
	@stow -n -v -t "$(XDG_CONFIG_HOME)" .config 2>&1 | grep -E "^(LINK|UNLINK)" || echo "    (no changes needed)"
	@echo ""
	@echo "Run 'make link' to apply these changes."

## Secret management
secrets-init:
	@bin/dotfiles-secrets init

secrets-status:
	@bin/dotfiles-secrets status

## Template system
template-list:
	@bin/dotfiles-template --list

## Docker-based testing (clean environment)
test-docker:
	@echo "Building and running tests in Ubuntu container..."
	docker build -t dotfiles-test -f test/Dockerfile .
	docker run --rm dotfiles-test

test-docker-arch:
	@echo "Building and running tests in Arch Linux container..."
	docker build -t dotfiles-test-arch -f test/Dockerfile.arch .
	docker run --rm dotfiles-test-arch

test-docker-interactive:
	@echo "Starting interactive Ubuntu container..."
	docker build -t dotfiles-test -f test/Dockerfile .
	docker run -it --rm dotfiles-test /bin/zsh

# ============================================================================
# Nix - Reproducible System Configuration
# ============================================================================

## Install Nix package manager
nix-install:
	@if command -v nix >/dev/null 2>&1; then \
		echo "✓ Nix already installed"; \
	else \
		echo "Installing Nix..."; \
		curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install; \
		echo "Please restart your shell and run 'make nix-darwin' or 'make nix-home'"; \
	fi

## Apply nix-darwin configuration (macOS full system)
nix-darwin:
	@echo "Applying nix-darwin configuration..."
	@if command -v darwin-rebuild >/dev/null 2>&1; then \
		darwin-rebuild switch --flake $(DOTFILES_DIR); \
	else \
		echo "First-time setup: bootstrapping nix-darwin..."; \
		nix run nix-darwin -- switch --flake $(DOTFILES_DIR); \
	fi
	@echo "✓ nix-darwin configuration applied"

## Apply Home Manager configuration (user environment only)
nix-home:
	@echo "Applying Home Manager configuration..."
	@if command -v home-manager >/dev/null 2>&1; then \
		home-manager switch --flake $(DOTFILES_DIR); \
	else \
		echo "First-time setup: bootstrapping Home Manager..."; \
		nix run home-manager -- switch --flake $(DOTFILES_DIR); \
	fi
	@echo "✓ Home Manager configuration applied"

## Alias for nix-darwin (primary macOS command)
nix: nix-darwin

## Update Nix flake inputs
nix-update:
	@echo "Updating Nix flake inputs..."
	nix flake update $(DOTFILES_DIR)
	@echo "✓ Flake inputs updated"
	@echo "Run 'make nix' or 'make nix-home' to apply updates"

## Check Nix flake for errors
nix-check:
	@echo "Checking Nix flake..."
	nix flake check $(DOTFILES_DIR)

## Garbage collect Nix store
nix-gc:
	@echo "Cleaning up Nix store..."
	nix-collect-garbage -d
	@if [ "$(OS)" = "macos" ]; then \
		sudo nix-collect-garbage -d; \
	fi
	@echo "✓ Nix garbage collection complete"

## Enter Nix development shell
nix-shell:
	nix develop $(DOTFILES_DIR)

# ============================================================================
# Go CLI
# ============================================================================

## Build the Go CLI installer
cli:
	@echo "Building dotfiles CLI..."
	@cd $(DOTFILES_DIR)/cmd/dotfiles && go build -o dotfiles-cli .
	@echo "✓ Built: cmd/dotfiles/dotfiles-cli"

## Install the Go CLI to GOPATH/bin
cli-install: cli
	@echo "Installing dotfiles CLI..."
	@cd $(DOTFILES_DIR)/cmd/dotfiles && go install .
	@echo "✓ Installed to GOPATH/bin"

# ============================================================================
# Help
# ============================================================================

## Show available make targets
help:
	@echo "Lorenzo's Dotfiles - Available Commands"
	@echo ""
	@echo "Installation (Traditional):"
	@echo "  make              - Full installation for detected OS"
	@echo "  make macos        - macOS installation (Homebrew-based)"
	@echo "  make arch         - Arch Linux installation"
	@echo "  make link         - Create symlinks only"
	@echo "  make unlink       - Remove symlinks"
	@echo ""
	@echo "Installation (Nix - Reproducible):"
	@echo "  make nix-install  - Install Nix package manager"
	@echo "  make nix          - Apply nix-darwin config (macOS)"
	@echo "  make nix-darwin   - Apply nix-darwin config (macOS)"
	@echo "  make nix-home     - Apply Home Manager config (cross-platform)"
	@echo "  make nix-update   - Update Nix flake inputs"
	@echo "  make nix-gc       - Garbage collect Nix store"
	@echo ""
	@echo "Packages:"
	@echo "  make brew-packages    - Install Homebrew formulae"
	@echo "  make cask-apps        - Install Homebrew casks"
	@echo "  make node-packages    - Install npm packages"
	@echo "  make rust-packages    - Install Cargo packages"
	@echo ""
	@echo "Maintenance:"
	@echo "  make doctor       - Run health check"
	@echo "  make update       - Update all packages"
	@echo "  make backup       - Backup configurations"
	@echo "  make clean        - Remove broken symlinks"
	@echo "  make test         - Run test suite"
	@echo ""
	@echo "See README.md and MAKEFILE.md for full documentation."
