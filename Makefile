# Where this Makefile lives, always. DOTFILES_DIR is the checkout being
# operated on and tests override it on the command line, so tools must be
# resolved from MAKEFILE_DIR and pointed at DOTFILES_DIR — not looked up
# inside the subject.
MAKEFILE_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
DOTFILES_DIR := $(MAKEFILE_DIR)
OS := $(shell bin/platform detect)
HOMEBREW_PREFIX := $(shell bin/platform select /opt/homebrew /usr/local "bin/platform is-arm64")
PATH := $(HOMEBREW_PREFIX)/bin:$(DOTFILES_DIR)/bin:$(PATH)
SHELL := env PATH=$(PATH) /bin/bash
# Evaluated at parse time so `make -n link` shows exactly what would run:
# nothing extra when stow is present, the Homebrew bootstrap when it is not.
HAVE_STOW := $(shell bin/platform has stow && echo yes)
BIN := $(HOMEBREW_PREFIX)/bin

# Written once because `link` and `link-dry-run` each used to carry their own
# copy. The copies had different escaping and only the dry-run one worked:
# make does not collapse `\\`, so `link`'s grep received an escaped backslash
# plus a quantifier instead of a literal `*`, never matched, and appended a
# fresh Include block to ~/.ssh/config on every single `make link`.
# Deferred (=) not immediate (:=) so `$$` survives to recipe expansion.
SSH_INCLUDE_LINE = Include ~/.config/ssh/config.d/*.conf
SSH_INCLUDE_RE = ^[[:space:]]*Include[[:space:]]+~/\.config/ssh/config\.d/\*\.conf([[:space:]]|$$)
ZSHENV_NEEDS_BACKUP = [ -f "$(HOME)/.zshenv" ] && [ ! -h "$(HOME)/.zshenv" ]
export XDG_CONFIG_HOME = $(HOME)/.config
export STOW_DIR = $(DOTFILES_DIR)
export ACCEPT_EULA=Y

.PHONY: all macos arch link unlink link-dry-run test test-setup verify \
        verify-shell verify-shellcheck verify-markdown verify-shell-surface verify-stale-refs verify-doc-links verify-tool-docs verify-doctor-tools verify-tests \
        doctor update backup worktree-add worktree-list worktree-remove worktree-prune \
        backup-compress backup-cleanup bench-shell daily clean restore restore-zshenv brew-update brew-cleanup \
        brew git packages-macos packages-arch core-macos core-arch \
        stow-arch stow-macos stow-linux linux unknown cask-apps cask-apps-extra vscode-extensions node-packages \
        rust-packages duti pacman-packages brew-packages \
        help \
        sync-install sync-uninstall sync-status sync-run \
        test-docker test-docker-arch test-docker-interactive verify-docker

all: $(OS)

macos: core-macos packages-macos link vscode-extensions duti

arch: core-arch packages-arch link

# Generic Linux (Debian, Fedora, …): no package manifests here; link only.
linux: link

# bin/platform detect returns a fourth value, "unknown", and without a target
# for it `make` on an unsupported OS died with "No rule to make target". Only
# install.sh covered for that, which is why its dispatch could disagree with
# this one.
unknown: link
	@echo "Unknown platform: linked configs only, no package manifests apply."

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

# Generic Linux: install stow with whatever package manager exists (needs sudo);
# otherwise say how.
stow-linux:
	@bin/platform has stow || { \
		if command -v apt-get >/dev/null 2>&1; then sudo apt-get install -y stow; \
		elif command -v dnf >/dev/null 2>&1; then sudo dnf install -y stow; \
		else echo "stow not found: install it with your package manager"; exit 1; fi; }

link: stow-$(OS)
	@echo "Linking dotfiles..."
	mkdir -p "$(XDG_CONFIG_HOME)"
	# Backup existing .zshenv if it exists and is not a symlink
	if $(ZSHENV_NEEDS_BACKUP); then \
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
	if ! grep -Eq '$(SSH_INCLUDE_RE)' "$(HOME)/.ssh/config"; then \
		printf "\n# Dotfiles managed SSH host snippets\n%s\n" '$(SSH_INCLUDE_LINE)' >> "$(HOME)/.ssh/config"; \
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
	bin/platform has brew || curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash

git: brew
	brew install git git-extras

packages-macos: brew-packages cask-apps node-packages rust-packages

packages-arch: pacman-packages

pacman-packages:
	@$(DOTFILES_DIR)/bin/install-kind pacman

brew-packages: brew
	@$(DOTFILES_DIR)/bin/install-kind brew

cask-apps: brew
	@$(DOTFILES_DIR)/bin/install-kind cask

# Optional apps (games, media production, misc). Not part of `make macos`.
cask-apps-extra: brew
	@$(DOTFILES_DIR)/bin/install-kind cask-extra

vscode-extensions: cask-apps
	@$(DOTFILES_DIR)/bin/install-kind code

# Node itself comes from the Brewfile (`brew "node"`), so npm is on PATH.
node-packages: brew-packages
	@$(DOTFILES_DIR)/bin/install-kind npm

rust-packages: brew-packages
	@$(DOTFILES_DIR)/bin/install-kind rust

duti:
	@if command -v duti >/dev/null 2>&1; then \
		echo "Setting default applications with duti..."; \
		duti -v $(DOTFILES_DIR)/install/duti; \
	else \
		echo "⚠️  duti not installed. Skipping default application setup."; \
		echo "   Install with: brew install duti"; \
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

verify: verify-shell verify-shellcheck verify-markdown verify-shell-surface verify-stale-refs verify-doc-links verify-tool-docs verify-doctor-tools verify-tests verify-docker
	@echo "✓ Verification complete"

# The container test is the only check that exercises the fresh-install path.
# Runs when a Docker daemon is reachable; otherwise says so loudly and moves on.
verify-docker:
	@if [ -n "$(SKIP_DOCKER)" ]; then echo "Skipping container test (SKIP_DOCKER set)"; \
	elif docker info >/dev/null 2>&1; then $(MAKE) test-docker; \
	else echo "⚠️  Docker not reachable; fresh-install container test SKIPPED (run 'make test-docker' where Docker exists)"; fi

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

# Mirrors the Lint job in .github/workflows/ci.yml. Kept here so `make verify`
# is a superset of CI rather than a subset of it: shellcheck and markdownlint
# used to run only in CI, which meant a green local gate could still fail on
# push. SKIP_LINTERS=1 opts out; a missing linter warns rather than failing,
# so a fresh checkout without npm still gets a usable `make verify`.
verify-shellcheck:
	@echo "Running shellcheck on bin/..."
	@if [ -n "$(SKIP_LINTERS)" ]; then \
		echo "Skipping shellcheck (SKIP_LINTERS set)"; \
	elif command -v shellcheck >/dev/null 2>&1; then \
		find bin -type f ! -name '*.md' -print0 \
			| xargs -0 grep -l '^#!.*\(bash\|sh\)' \
			| xargs shellcheck --severity=warning -x; \
	else \
		echo "⚠️  shellcheck not found; SKIPPED (CI runs it — brew install shellcheck)"; \
	fi

verify-markdown:
	@echo "Running markdownlint..."
	@if [ -n "$(SKIP_LINTERS)" ]; then \
		echo "Skipping markdownlint (SKIP_LINTERS set)"; \
	elif command -v markdownlint >/dev/null 2>&1; then \
		markdownlint -c .markdownlint.json --ignore .github --ignore test "**/*.md"; \
	elif [ -x "$$(npm config get prefix 2>/dev/null)/bin/markdownlint" ]; then \
		"$$(npm config get prefix)/bin/markdownlint" -c .markdownlint.json --ignore .github --ignore test "**/*.md"; \
	else \
		echo "⚠️  markdownlint not found; SKIPPED (CI runs it — npm i -g markdownlint-cli)"; \
	fi

verify-doctor-tools:
	@echo "Validating dotfiles-doctor tool lists against manifests..."
	@bin/validate-doctor-tools

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

# Removes only broken links that pointed into this checkout; broken links
# owned by other tools under ~/.config are left alone. The ownership rule
# (lexical resolution, because a broken link's target cannot be canonicalised
# on disk) lives in bin/link-state, which dotfiles-doctor reads too.
clean:
	@echo "Cleaning broken symlinks..."
	@DOTFILES_DIR="$(DOTFILES_DIR)" $(MAKEFILE_DIR)/bin/link-state | \
		awk -F'\t' '$$1 == "broken-ours" { print $$2 }' | \
		while IFS= read -r link; do rm -f "$$link"; echo "Removed $$link"; done
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
	@if $(ZSHENV_NEEDS_BACKUP); then \
		echo "    Would backup: $(HOME)/.zshenv -> $(HOME)/.zshenv.bak"; \
	fi
	@echo "    Would create: $(HOME)/.zshenv -> $(DOTFILES_DIR)/.zshenv"
	@echo ""
	@echo "==> .config symlinks (via stow):"
	@stow -n -v -t "$(XDG_CONFIG_HOME)" .config 2>&1 | grep -E "^(LINK|UNLINK)" || echo "    (no changes needed)"
	@echo ""
	@echo "==> SSH include:"
	@if grep -Eq '$(SSH_INCLUDE_RE)' "$(HOME)/.ssh/config" 2>/dev/null; then \
		echo "    Include already present in $(HOME)/.ssh/config"; \
	else \
		echo "    Would append: $(SSH_INCLUDE_LINE)"; \
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
	@echo "  make cask-apps        - Install day-one Homebrew casks (install/Caskfile)"
	@echo "  make cask-apps-extra  - Install optional casks (install/Caskfile.extra)"
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
	@echo "Environment:"
	@echo "  SKIP_KINDS=\"rust pacman\"  - Skip these manifest kinds"
	@echo "                          (brew cask cask-extra npm rust pacman code)"
	@echo "  STRICT_PACKAGES=1       - Make a package install failure fatal"
	@echo "  SKIP_DOCKER=1           - Skip the container test in make verify"
	@echo "  SKIP_LINTERS=1          - Skip shellcheck/markdownlint in make verify"
	@echo ""
	@echo "See README.md for full documentation."
