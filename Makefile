DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
OS := $(shell bin/platform detect)
HOMEBREW_PREFIX := $(shell bin/platform select /opt/homebrew /usr/local "bin/platform is-arm64")
export N_PREFIX = $(HOME)/.n
NIX_PROFILE_BIN := /nix/var/nix/profiles/default/bin
PATH := $(HOMEBREW_PREFIX)/bin:$(NIX_PROFILE_BIN):$(DOTFILES_DIR)/bin:$(N_PREFIX)/bin:$(PATH)
SHELL := env PATH=$(PATH) /bin/bash
SHELLS := /private/etc/shells
BIN := $(HOMEBREW_PREFIX)/bin
export XDG_CONFIG_HOME = $(HOME)/.config
export STOW_DIR = $(DOTFILES_DIR)
export ACCEPT_EULA=Y

.PHONY: all macos arch link unlink link-dry-run sudo test test-setup verify \
        verify-shell verify-stale-refs verify-doc-links verify-tool-docs verify-tests verify-nix \
        doctor update backup worktree-add worktree-list worktree-remove worktree-prune \
        backup-compress backup-cleanup bench-shell daily clean restore restore-zshenv brew-update brew-cleanup \
        brew bash git npm packages-macos packages-arch core-macos core-arch \
        stow-arch stow-macos cask-apps vscode-extensions node-packages \
        rust-packages duti bun pacman-packages brew-packages \
        nix nix-install nix-darwin nix-home nix-update nix-check nix-gc nix-shell help \
        sync-install sync-uninstall sync-status sync-run \
        test-docker test-docker-arch test-docker-interactive

all: $(OS)

macos: sudo core-macos packages-macos link duti bun

arch: core-arch packages-arch link

core-macos: brew bash git

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
	if [ -f "$(HOME)/.zshenv" ] && [ ! -h "$(HOME)/.zshenv" ]; then \
		mv -v "$(HOME)/.zshenv" "$(HOME)/.zshenv.bak"; \
	fi
	# Link .zshenv to home directory
	ln -sf "$(DOTFILES_DIR)/.zshenv" "$(HOME)/.zshenv"
	# Link .config directory contents
	stow -t "$(XDG_CONFIG_HOME)" .config
	# Ensure OpenSSH includes dotfiles-managed host snippets
	mkdir -p "$(HOME)/.ssh"
	chmod 700 "$(HOME)/.ssh"
	touch "$(HOME)/.ssh/config"
	chmod 600 "$(HOME)/.ssh/config"
	if ! grep -Eq '^[[:space:]]*Include[[:space:]]+~/.config/ssh/config.d/\\*\\.conf([[:space:]]|$$)' "$(HOME)/.ssh/config"; then \
		printf "\n# Dotfiles managed SSH host snippets\nInclude ~/.config/ssh/config.d/*.conf\n" >> "$(HOME)/.ssh/config"; \
	fi
	mkdir -p "$(HOME)/.local/runtime"
	chmod 700 "$(HOME)/.local/runtime"
	@echo "Dotfiles linked successfully!"

unlink: stow-$(OS)
	@echo "Unlinking dotfiles..."
	stow --delete -t "$(XDG_CONFIG_HOME)" .config
	# Remove .zshenv symlink
	rm -f "$(HOME)/.zshenv"
	# Restore backup if it exists
	if [ -f "$(HOME)/.zshenv.bak" ]; then \
		mv -v "$(HOME)/.zshenv.bak" "$(HOME)/.zshenv"; \
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
	@if [ -n "$(SKIP_NPM)" ]; then \
		echo "Skipping Node.js runtime installation"; \
	else \
		n install lts; \
	fi

packages-macos: brew-packages cask-apps node-packages rust-packages

packages-arch: pacman-packages

pacman-packages:
	pacman -S --noconfirm - < $(DOTFILES_DIR)/install/pacmanfile

brew-packages: brew
	if [ -n "$(SKIP_BREW)" ]; then \
		echo "Skipping Homebrew formulae"; \
	elif [ -n "$(BREW_BUNDLE_STRICT)" ]; then \
		brew bundle --file=$(DOTFILES_DIR)/install/Brewfile; \
	else \
		brew bundle --file=$(DOTFILES_DIR)/install/Brewfile || true; \
	fi

cask-apps: brew
	if [ -n "$(SKIP_CASKS)" ]; then \
		echo "Skipping Homebrew casks"; \
	elif [ -n "$(BREW_BUNDLE_STRICT)" ]; then \
		brew bundle --file=$(DOTFILES_DIR)/install/Caskfile; \
	else \
		brew bundle --file=$(DOTFILES_DIR)/install/Caskfile || true; \
	fi

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
	@if [ -n "$(SKIP_NPM)" ]; then \
		echo "Skipping npm packages"; \
	else \
		$(N_PREFIX)/bin/npm install --force --location global $(shell cat install/npmfile); \
	fi

rust-packages: brew-packages
	@if [ -n "$(SKIP_RUST)" ]; then \
		echo "Skipping Rust packages"; \
	else \
		cargo install $(shell cat install/Rustfile); \
	fi

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
	@if ! command -v bats >/dev/null 2>&1; then \
		echo "Error: bats is not installed."; \
		echo "Run 'make test-setup' and then retry."; \
		exit 1; \
	fi
	bats test

test-setup:
	@echo "Installing test dependencies (bats)..."
	@if command -v bats >/dev/null 2>&1; then \
		echo "✓ bats already installed"; \
	elif command -v brew >/dev/null 2>&1; then \
		brew install bats-core; \
	elif command -v apt-get >/dev/null 2>&1; then \
		sudo apt-get update && sudo apt-get install -y bats; \
	elif command -v pacman >/dev/null 2>&1; then \
		sudo pacman -Sy --noconfirm bats; \
	else \
		echo "Could not auto-install bats on this platform."; \
		echo "Install bats manually and re-run 'make test'."; \
		exit 1; \
	fi

verify: verify-shell verify-stale-refs verify-doc-links verify-tool-docs verify-tests verify-nix
	@echo "✓ Verification complete"

verify-shell:
	@echo "Running shell syntax checks..."
	@if command -v zsh >/dev/null 2>&1; then \
		zsh -n .zshenv .config/zsh/.zshrc .config/zsh/aliases.zsh; \
	else \
		echo "⚠️  zsh not found; skipping zsh syntax checks"; \
	fi
	@for script in bin/*; do \
		if [ -f "$$script" ] && head -n1 "$$script" | grep -q "bash"; then \
			bash -n "$$script"; \
		fi; \
	done

verify-stale-refs:
	@echo "Checking for stale migration references..."
	@PATTERN='OneHalfDark|\.config/\.aliases|org\.alacritty|tokyonight|LF_ICONS|CODE_QUALITY_REPORT|lorenozsca7|oh-my-zsh|Oh My Zsh'; \
	SCAN_PATHS='README.md OPERATING.md CLAUDE.md .config bin nix .zshenv flake.nix'; \
	if command -v rg >/dev/null 2>&1; then \
		if rg -n "$$PATTERN" $$SCAN_PATHS >/dev/null; then \
			echo "Found stale references:"; \
			rg -n "$$PATTERN" $$SCAN_PATHS; \
			exit 1; \
		fi; \
	else \
		if grep -R -nE "$$PATTERN" $$SCAN_PATHS >/dev/null; then \
			echo "Found stale references:"; \
			grep -R -nE "$$PATTERN" $$SCAN_PATHS; \
			exit 1; \
		fi; \
	fi

verify-doc-links:
	@echo "Validating markdown links..."
	@bin/validate-doc-links

verify-tool-docs:
	@echo "Validating tool catalog..."
	@bin/validate-tool-docs

verify-tests:
	@$(MAKE) test

verify-nix:
	@echo "Checking Nix flake..."
	@if command -v nix >/dev/null 2>&1; then \
		nix flake check --no-build $(DOTFILES_DIR); \
	else \
		echo "⚠️  nix not found; skipping flake check"; \
	fi

## Run core pre-push checks (fast local confidence loop)
daily: verify-shell verify-doc-links verify-tests
	@echo "✓ Daily checks passed"

doctor:
	@bin/dotfiles-doctor

update:
	@bin/dotfiles-update

backup:
	@bin/dotfiles-backup

## Benchmark interactive zsh startup against a performance budget
bench-shell:
	@bin/dotfiles-bench-shell --runs "$(if $(runs),$(runs),7)" --budget-ms "$(if $(budget),$(budget),900)"

## Create an isolated worktree for a parallel session
worktree-add:
	@if [ -z "$(name)" ]; then \
		echo "Usage: make worktree-add name=<task> [base=<branch>]"; \
		exit 1; \
	fi
	@bin/dotfiles-worktree add "$(name)" "$(if $(base),$(base),main)"

## List active worktrees
worktree-list:
	@bin/dotfiles-worktree list

## Remove a worktree by name (or use path via script directly)
worktree-remove:
	@if [ -z "$(name)" ]; then \
		echo "Usage: make worktree-remove name=<task> [force=1]"; \
		exit 1; \
	fi
	@if [ -n "$(force)" ]; then \
		bin/dotfiles-worktree remove --force "$(name)"; \
	else \
		bin/dotfiles-worktree remove "$(name)"; \
	fi

## Prune stale worktree metadata
worktree-prune:
	@bin/dotfiles-worktree prune

backup-compress:
	@bin/dotfiles-backup --compress

backup-cleanup:
	@bin/dotfiles-backup --cleanup

# ============================================================================
# Automated Sync - Daily git pull via launchd
# ============================================================================

LAUNCH_AGENTS := $(HOME)/Library/LaunchAgents
SYNC_PLIST := com.dotfiles.sync.plist

## Install automated daily sync service (macOS only)
sync-install:
	@echo "Installing dotfiles sync service..."
	@mkdir -p $(LAUNCH_AGENTS)
	@sed "s|__DOTFILES_DIR__|$(DOTFILES_DIR)|g" .config/macos/$(SYNC_PLIST) \
	    > $(LAUNCH_AGENTS)/$(SYNC_PLIST)
	@launchctl load $(LAUNCH_AGENTS)/$(SYNC_PLIST)
	@echo "✓ Sync service installed (runs daily at 10:00 AM)"
	@echo "  Run 'make sync-status' to verify"

## Remove automated sync service
sync-uninstall:
	@echo "Removing dotfiles sync service..."
	@launchctl unload $(LAUNCH_AGENTS)/$(SYNC_PLIST) 2>/dev/null || true
	@rm -f $(LAUNCH_AGENTS)/$(SYNC_PLIST)
	@echo "✓ Sync service removed"

## Check sync service status
sync-status:
	@echo "Sync service status:"
	@launchctl list | grep -E "PID|dotfiles.sync" || echo "  Service not loaded"
	@echo ""
	@if [ -f /tmp/dotfiles-sync.err ]; then \
		echo "Recent errors (if any):"; \
		tail -5 /tmp/dotfiles-sync.err 2>/dev/null || echo "  (none)"; \
	fi

## Run sync manually (for testing)
sync-run:
	@bin/dotfiles-sync

clean:
	@echo "Cleaning broken symlinks..."
	@find "$(HOME)/.config" -type l ! -exec test -e {} \; -delete 2>/dev/null || true
	@if [ -h "$(HOME)/.zshenv" ] && [ ! -e "$(HOME)/.zshenv" ]; then \
		rm -f "$(HOME)/.zshenv"; \
		echo "Removed broken .zshenv symlink"; \
	fi
	@echo "✓ Cleanup complete"

## Restore files from a dotfiles-backup snapshot (default: latest)
restore:
	@bin/dotfiles-restore $(if $(backup),$(backup),)

## Restore legacy .zshenv backup created during link/unlink flow
restore-zshenv:
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
	@if [ -f "$(HOME)/.zshenv" ] && [ ! -h "$(HOME)/.zshenv" ]; then \
		echo "    Would backup: $(HOME)/.zshenv -> $(HOME)/.zshenv.bak"; \
	fi
	@echo "    Would create: $(HOME)/.zshenv -> $(DOTFILES_DIR)/.zshenv"
	@echo ""
	@echo "==> .config symlinks (via stow):"
	@stow -n -v -t "$(XDG_CONFIG_HOME)" .config 2>&1 | grep -E "^(LINK|UNLINK)" || echo "    (no changes needed)"
	@echo ""
	@echo "==> SSH include:"
	@if grep -Eq '^[[:space:]]*Include[[:space:]]+~/.config/ssh/config.d/\*\.conf([[:space:]]|$$)' "$(HOME)/.ssh/config" 2>/dev/null; then \
		echo "    Include already present in $(HOME)/.ssh/config"; \
	else \
		echo "    Would append: Include ~/.config/ssh/config.d/*.conf"; \
	fi
	@echo ""
	@echo "Run 'make link' to apply these changes."

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
# Nix - Optional Reproducible Configuration (delegates to bin/dotfiles-nix)
# ============================================================================

nix-install:
	@bin/dotfiles-nix install

nix-darwin:
	@bin/dotfiles-nix darwin

nix-home:
	@bin/dotfiles-nix home

nix: nix-darwin

nix-update:
	@bin/dotfiles-nix update

nix-check:
	@bin/dotfiles-nix check

nix-gc:
	@bin/dotfiles-nix gc

nix-shell:
	@bin/dotfiles-nix shell

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
	@echo "Installation (Nix - Optional):"
	@echo "  make nix-install  - Install Nix package manager"
	@echo "  make nix          - Apply nix-darwin config (macOS)"
	@echo "  make nix-darwin   - Apply nix-darwin config (macOS)"
	@echo "  make nix-home     - Apply Home Manager config (cross-platform)"
	@echo "  make nix-update   - Update Nix flake inputs"
	@echo "  make nix-check    - Check Nix flake for errors"
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
	@echo "  make restore [backup=/path] - Restore latest/specified backup snapshot"
	@echo "  make restore-zshenv - Restore legacy .zshenv backup only"
	@echo "  make bench-shell [runs=7] [budget=900] - Benchmark zsh startup budget"
	@echo "  make daily        - Run core pre-push checks (shell, docs, tests)"
	@echo "  make worktree-add name=<task> [base=main] - New isolated worktree"
	@echo "  make worktree-list - List worktrees"
	@echo "  make worktree-remove name=<task> [force=1] - Remove worktree"
	@echo "  make worktree-prune - Prune stale worktree metadata"
	@echo "  make clean        - Remove broken symlinks"
	@echo "  make test-setup   - Install test dependencies (bats)"
	@echo "  make test         - Run test suite"
	@echo "  make verify       - Run full repository verification"
	@echo ""
	@echo "Automated Sync (macOS):"
	@echo "  make sync-install   - Enable daily auto-sync"
	@echo "  make sync-uninstall - Disable auto-sync"
	@echo "  make sync-status    - Check sync service status"
	@echo "  make sync-run       - Run sync manually"
	@echo ""
	@echo "See README.md for full documentation."
