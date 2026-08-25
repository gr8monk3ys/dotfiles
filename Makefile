DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
OS := $(shell bin/platform detect)
HOMEBREW_PREFIX := $(shell bin/platform select /opt/homebrew /usr/local "bin/platform is-arm64")
PATH := $(HOMEBREW_PREFIX)/bin:$(DOTFILES_DIR)/bin:$(PATH)
SHELL := env PATH=$(PATH) /bin/bash
# Evaluated at parse time so `make -n link` shows exactly what would run:
# nothing extra when stow is present, the Homebrew bootstrap when it is not.
HAVE_STOW := $(shell bin/platform has stow && echo yes)
BIN := $(HOMEBREW_PREFIX)/bin
export XDG_CONFIG_HOME = $(HOME)/.config
export STOW_DIR = $(DOTFILES_DIR)
export ACCEPT_EULA=Y

.PHONY: all macos arch link unlink link-dry-run test test-setup verify \
        verify-shell verify-shell-surface verify-stale-refs verify-doc-links verify-tool-docs verify-tests \
        doctor update backup worktree-add worktree-list worktree-remove worktree-prune \
        backup-compress backup-cleanup bench-shell daily clean restore restore-zshenv brew-update brew-cleanup \
        brew git packages-macos packages-arch core-macos core-arch \
        stow-arch stow-macos stow-linux linux cask-apps vscode-extensions node-packages \
        rust-packages duti bun pacman-packages brew-packages \
        help \
        sync-install sync-uninstall sync-status sync-run \
        test-docker test-docker-arch test-docker-interactive

all: $(OS)

macos: core-macos packages-macos link vscode-extensions duti bun

arch: core-arch packages-arch link

# Generic Linux (Debian, Fedora, …): no package manifests here; link only.
linux: link

core-macos: brew git

core-arch:
	pacman -Syu --noconfirm

stow-arch: core-arch
	bin/platform has stow || pacman -S --noconfirm stow

# Only pull in the Homebrew bootstrap when stow is actually missing, so
# `make link` on a machine that already has stow touches nothing else.
ifeq ($(HAVE_STOW),yes)
stow-macos:
	@true
else
stow-macos: brew
	brew install stow
endif

stow-linux:
	@bin/platform has stow || { echo "stow not found: install it with your package manager (apt/dnf install stow)"; exit 1; }

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

git: brew
	brew install git git-extras

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

# Node itself comes from the Brewfile (`brew "node"`), so npm is on PATH.
node-packages: brew-packages
	@if [ -n "$(SKIP_NPM)" ]; then \
		echo "Skipping npm packages"; \
	else \
		grep -Ev '^\s*(#|$$)' install/npmfile | xargs npm install --force --location global; \
	fi

rust-packages: brew-packages
	@if [ -n "$(SKIP_RUST)" ]; then \
		echo "Skipping Rust packages"; \
	else \
		grep -Ev '^\s*(#|$$)' install/Rustfile | xargs -n1 cargo install; \
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

verify: verify-shell verify-shell-surface verify-stale-refs verify-doc-links verify-tool-docs verify-tests
	@echo "✓ Verification complete"

verify-shell:
	@echo "Running shell syntax checks..."
	@if command -v zsh >/dev/null 2>&1; then \
		zsh -n .zshenv .config/zsh/.zshrc .config/zsh/aliases.zsh .config/zsh/functions.zsh; \
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
	SCAN_PATHS='README.md OPERATING.md CLAUDE.md .config bin .zshenv'; \
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

verify-shell-surface:
	@echo "Running shell-surface tests..."
	@bats test/test_shell_surface.bats test/test_alias_checker.bats

verify-tool-docs:
	@echo "Validating tool catalog..."
	@bin/validate-tool-docs

verify-tests:
	@$(MAKE) test

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
SYNC_LOG := $(HOME)/Library/Logs/dotfiles-sync.log

## Install automated daily sync service (macOS only)
sync-install:
	@echo "Installing dotfiles sync service..."
	@mkdir -p $(LAUNCH_AGENTS) $(HOME)/Library/Logs
	@sed -e "s|__DOTFILES_DIR__|$(DOTFILES_DIR)|g" -e "s|__SYNC_LOG__|$(SYNC_LOG)|g" \
	    .config/macos/$(SYNC_PLIST) > $(LAUNCH_AGENTS)/$(SYNC_PLIST)
	@plutil -lint $(LAUNCH_AGENTS)/$(SYNC_PLIST)
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
	@if [ -s "$(SYNC_LOG)" ]; then \
		echo "Recent log ($(SYNC_LOG)):"; \
		tail -5 "$(SYNC_LOG)"; \
	else \
		echo "No log output yet ($(SYNC_LOG))"; \
	fi

## Run sync manually (for testing)
sync-run:
	@bin/dotfiles-sync

# Only removes broken links that pointed into this checkout; broken links
# owned by other tools under ~/.config are left alone. Targets are resolved
# lexically (readlink + ../ collapsing) because a broken link's target
# cannot be canonicalised on disk.
clean:
	@echo "Cleaning broken symlinks..."
	@find "$(HOME)/.config" -type l ! -exec test -e {} \; -print 2>/dev/null | while IFS= read -r link; do \
		target="$$(readlink "$$link")"; \
		[ "$${target#/}" = "$$target" ] && target="$$(dirname "$$link")/$$target"; \
		norm=""; IFS=/; for part in $$target; do \
			case "$$part" in ''|.) ;; ..) norm="$${norm%/*}" ;; *) norm="$$norm/$$part" ;; esac; \
		done; unset IFS; \
		case "$$norm" in "$(DOTFILES_DIR)"/*) rm -f "$$link"; echo "Removed $$link" ;; esac; \
	done
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
	docker build --platform linux/amd64 -t dotfiles-test-arch -f test/Dockerfile.arch .
	docker run --platform linux/amd64 --rm dotfiles-test-arch

test-docker-interactive:
	@echo "Starting interactive Ubuntu container..."
	docker build -t dotfiles-test -f test/Dockerfile .
	docker run -it --rm dotfiles-test /bin/zsh

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
	@echo "  make link-dry-run - Show what link would do without changing anything"
	@echo "  make unlink       - Remove symlinks"
	@echo ""
	@echo "Packages:"
	@echo "  make brew-packages    - Install Homebrew formulae"
	@echo "  make cask-apps        - Install Homebrew casks"
	@echo "  make node-packages    - Install npm packages"
	@echo "  make rust-packages    - Install Cargo packages"
	@echo "  make vscode-extensions - Install Codefile extensions (VSCodium/VS Code)"
	@echo "  make duti             - Set macOS default apps from install/duti"
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
	@echo "  make test-docker  - Run test suite in an Ubuntu container"
	@echo "  make test-docker-arch - Run test suite in an Arch container"
	@echo "  make verify       - Run full repository verification"
	@echo ""
	@echo "Automated Sync (macOS):"
	@echo "  make sync-install   - Enable daily auto-sync"
	@echo "  make sync-uninstall - Disable auto-sync"
	@echo "  make sync-status    - Check sync service status"
	@echo "  make sync-run       - Run sync manually"
	@echo ""
	@echo "See README.md for full documentation."
