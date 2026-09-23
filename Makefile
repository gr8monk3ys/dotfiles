# Where this Makefile lives, always. DOTFILES_DIR is the checkout being
# operated on and tests override it on the command line, so tools must be
# resolved from MAKEFILE_DIR and pointed at DOTFILES_DIR — not looked up
# inside the subject.
MAKEFILE_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
DOTFILES_DIR := $(MAKEFILE_DIR)
PLATFORM := "$(MAKEFILE_DIR)/bin/platform"
OS := $(shell $(PLATFORM) detect)
HOMEBREW_PREFIX := $(shell $(PLATFORM) select /opt/homebrew /usr/local '$(PLATFORM) is-arm64')
PATH := $(HOMEBREW_PREFIX)/bin:$(DOTFILES_DIR)/bin:$(PATH)
# PATH is passed through env rather than exported because make 3.81 (macOS)
# resolves simple commands against its own PATH, not the exported one. The
# quotes are load-bearing: unquoted, one PATH entry with a space in it (the
# Claude desktop app adds several) splits the SHELL value and every recipe
# exits 127.
SHELL := env PATH='$(PATH)' /bin/bash
# Evaluated at parse time so `make -n link` shows exactly what would run:
# nothing extra when stow is present, the Homebrew bootstrap when it is not.
HAVE_STOW := $(shell $(PLATFORM) has stow && echo yes)

# Yes/no switches (SKIP_DOCKER, SKIP_LINTERS, …): `1` or `true` means yes,
# anything else means no. Testing for "non-empty" made SKIP_DOCKER=0 skip.
truthy = $(filter 1 true,$(strip $(1)))
export XDG_CONFIG_HOME = $(HOME)/.config
# Linking is bin/link's job: apply, dry-run and undo are one planner there, and
# it owns the SSH Include line, the .zshenv backup and the tool-owned list.
# HOME and XDG_CONFIG_HOME are passed explicitly so `make link HOME=/tmp/x`
# (the tests) cannot reach the real home through an inherited value.
LINK = DOTFILES_DIR="$(DOTFILES_DIR)" HOME="$(HOME)" XDG_CONFIG_HOME="$(XDG_CONFIG_HOME)" "$(MAKEFILE_DIR)/bin/link"

.PHONY: all macos arch link unlink link-dry-run test test-setup verify \
        verify-config-live verify-palette verify-shellcheck verify-markdown verify-stale-refs verify-doc-links verify-tests \
        doctor init update backup firefox worktree-add worktree-list worktree-remove worktree-prune \
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

# pacman needs root. Escalate here rather than through a wrapper that shadows
# pacman on PATH (bin/pacman, now gone); install-kind does the same in bash.
AS_ROOT := $(if $(filter 0,$(shell id -u)),,sudo)

# The system upgrade is the pacman kind's update, so SKIP_KINDS=pacman skips it.
core-arch:
	@$(DOTFILES_DIR)/bin/install-kind update pacman

# Only stow, never a system upgrade: `link` depends on this, and it used to
# depend on core-arch, so refreshing symlinks on Arch ran `pacman -Syu`.
# --needed makes it a no-op if stow is already there. `make arch` still runs
# core-arch first on its own.
stow-arch:
	$(PLATFORM) has stow || $(AS_ROOT) pacman -S --needed --noconfirm stow

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
	@$(LINK) apply

unlink: stow-$(OS)
	@$(LINK) undo

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

# The one way the suite's prerequisites get installed: CI's Tests jobs and
# both container images call this rather than carrying their own recipe.
# bats-support/bats-assert are real prerequisites, not optional: without them
# test_helper/common.bash falls back to a three-function shim. zsh and stow
# are what the suite exercises. Dispatches on $(OS), not on `command -v`:
# bin/ is on PATH and bin/pacman is a wrapper, so `command -v pacman` is true
# on every machine, and a Linux runner with Linuxbrew must still use apt.
# Idempotent, so it re-runs cheaply. Ubuntu before 24.04 ships a bats too old
# for the suite (it needs 1.5 for `run --separate-stderr`).
test-setup:
	@echo "Installing test dependencies (bats, bats-support, bats-assert, zsh, stow)..."
	@case "$(OS)" in \
	arch) \
		sudo pacman -S --needed --noconfirm bats bats-support bats-assert zsh stow ;; \
	macos) \
		brew install bats-core stow && \
		brew tap bats-core/bats-core && \
		{ brew trust bats-core/bats-core 2>/dev/null || true; } && \
		brew install bats-support bats-assert ;; \
	*) \
		if command -v apt-get >/dev/null 2>&1; then \
			sudo apt-get update && \
			sudo apt-get install -y --no-install-recommends bats bats-support bats-assert zsh stow; \
		else \
			echo "Could not auto-install bats on this platform."; \
			echo "Install bats-core, bats-support and bats-assert, then re-run 'make test'."; \
			exit 1; \
		fi ;; \
	esac

# No separate syntax or shell-surface steps: shellcheck parses every bin/
# script, and the suite (verify-tests) parses and sources the zsh surface.
# Both used to run here as well, so each check ran two or three times.
verify: verify-shellcheck verify-markdown verify-stale-refs verify-palette verify-doc-links verify-tests verify-docker
	@echo "✓ Verification complete"

# The containers are the only local checks that run a platform's real `make`
# on a clean machine, and the only ones that run the suite on Linux. Arch is a
# supported platform, so its container installs the whole pacmanfile via
# `make arch` (about 1.2 GB of packages); Ubuntu is generic Linux, link only.
# Run when a Docker daemon is reachable; otherwise say so loudly and move on.
#
# Cost: upstream publishes no arm64 archlinux image, so on Apple Silicon the
# Arch container runs under linux/amd64 emulation and takes roughly 25
# minutes, against well under a minute for Ubuntu. SKIP_ARCH_DOCKER=1 drops
# it locally; CI's Container (arch) job runs it natively on every PR.
verify-docker:
	@if [ -n "$(call truthy,$(SKIP_DOCKER))" ]; then echo "Skipping container tests (SKIP_DOCKER set)"; \
	elif docker info >/dev/null 2>&1; then \
		$(MAKE) test-docker && \
		if [ -n "$(call truthy,$(SKIP_ARCH_DOCKER))" ]; then echo "Skipping Arch container test (SKIP_ARCH_DOCKER set)"; \
		else $(MAKE) test-docker-arch; fi; \
	else echo "⚠️  Docker not reachable; fresh-install container tests SKIPPED (run 'make test-docker test-docker-arch' where Docker exists)"; fi

# Retired palette hexes are not listed here any more: every colour outside
# prose is rendered from .config/palette/danse.conf and checked by
# verify-palette; test_palette.bats fails on a colour literal anywhere else.
verify-stale-refs:
	@echo "Checking for stale migration references..."
	@PATTERN='OneHalfDark|base16-onedark|\.config/\.aliases|org\.alacritty|tokyonight|LF_ICONS|CODE_QUALITY_REPORT|lorenozsca7|oh-my-zsh|Oh My Zsh'; \
	SCAN_PATHS='README.md OPERATING.md CLAUDE.md .config bin .zshenv install.sh'; \
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

# Every rendered file must match what its template produces from the palette;
# a hand-edited rendered file or a stale one after a retune fails here.
verify-palette:
	@echo "Checking rendered palette files..."
	@bin/palette check

verify-doc-links:
	@echo "Validating markdown links..."
	@bin/validate-doc-links

# Mirrors the Lint job in .github/workflows/ci.yml. Kept here so `make verify`
# is a superset of CI rather than a subset of it: shellcheck and markdownlint
# used to run only in CI, which meant a green local gate could still fail on
# push. SKIP_LINTERS=1 opts out; a missing linter warns rather than failing,
# so a fresh checkout without npm still gets a usable `make verify`.
verify-shellcheck:
	@echo "Running shellcheck on bin/..."
	@if [ -n "$(call truthy,$(SKIP_LINTERS))" ]; then \
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
	@if [ -n "$(call truthy,$(SKIP_LINTERS))" ]; then \
		echo "Skipping markdownlint (SKIP_LINTERS set)"; \
	elif command -v markdownlint >/dev/null 2>&1; then \
		markdownlint -c .markdownlint.json --ignore .github --ignore test "**/*.md"; \
	elif [ -x "$$(npm config get prefix 2>/dev/null)/bin/markdownlint" ]; then \
		"$$(npm config get prefix)/bin/markdownlint" -c .markdownlint.json --ignore .github --ignore test "**/*.md"; \
	else \
		echo "⚠️  markdownlint not found; SKIPPED (CI runs it — npm i -g markdownlint-cli)"; \
	fi

# Not in `make verify`: the probes assert on discovery variables a login
# shell exports, and `make` does not run one. It is a machine check — run it
# after `make link` or when a tool stops behaving.
verify-config-live:
	@echo "Checking tracked configs are actually honoured..."
	@$(MAKEFILE_DIR)/bin/validate-config-live

verify-tests:
	@$(MAKE) test

## Run core pre-push checks (fast local confidence loop)
daily: verify-doc-links verify-tests
	@echo "✓ Daily checks passed"

doctor:
	@bin/dotfiles-doctor

## Create the gitignored local files `make` cannot: git and jj identity
# The values are named here rather than left to leak through the environment so
# that `make init GIT_USER_NAME=…` and `GIT_USER_NAME=… make init` behave the
# same, and so the documentation check in test_dotfiles_init.bats can see which
# variables this Makefile reads. Resolved from MAKEFILE_DIR like every other
# tool here, never looked up inside DOTFILES_DIR.
init:
	@GIT_USER_NAME="$(GIT_USER_NAME)" GIT_USER_EMAIL="$(GIT_USER_EMAIL)" \
	 GIT_SIGNING_KEY="$(GIT_SIGNING_KEY)" \
	 JJ_USER_NAME="$(JJ_USER_NAME)" JJ_USER_EMAIL="$(JJ_USER_EMAIL)" \
	 $(MAKEFILE_DIR)/bin/dotfiles-init $(if $(check),--check)

update:
	@bin/dotfiles-update

backup:
	@bin/dotfiles-backup

## Install this checkout's user.js into the Firefox profiles that read it
# Not folded into `link`: stow's target (~/.config/firefox/user.js) is a path
# Firefox never opens, and a browser profile is not something `make link`
# should reach into unasked. Resolved from MAKEFILE_DIR like every other tool
# here — never looked up inside DOTFILES_DIR, which tests point elsewhere.
firefox:
	@DOTFILES_DIR="$(DOTFILES_DIR)" $(MAKEFILE_DIR)/bin/firefox-user-js install \
		$(if $(filter all,$(profiles)),--all) $(if $(copy),--copy) $(if $(dry),--dry-run)

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

## Restore the .zshenv that `make link` backed up
# Kept as a name only. Restoring the backup is part of undo, and this recipe's
# own copy of that logic moved the backup over whatever was at ~/.zshenv.
restore-zshenv: unlink

brew-update:
	@echo "Updating Homebrew..."
	@brew update && brew upgrade
	@echo "✓ Homebrew updated"

brew-cleanup:
	@echo "Cleaning up Homebrew..."
	@brew cleanup
	@echo "✓ Homebrew cleanup complete"

## Dry-run: print what `make link` would do, changing nothing
# No stow-$(OS) prerequisite: a preview must not install anything. bin/link
# says so if stow is missing and previews the rest.
link-dry-run:
	@$(LINK) dry-run

## Docker-based testing (clean environment)
# One Dockerfile (test/Dockerfile), one pinned base image per distro. The
# container runs the platform's real `make` path, then the suite and doctor.
# Upstream publishes no arm64 archlinux image, so Arch always runs as
# linux/amd64: native on CI runners, emulated (and slow) on Apple Silicon.
DOCKER_BASE_ubuntu := ubuntu:24.04@sha256:008173c23f95b170204355c12626cb5a965d779a7e1283b09e9cffbb1bf33ca3
DOCKER_BASE_arch := archlinux:latest@sha256:bb1e5dd58eb79755e736ac530292074f4408572c0fbc4306cd62b431fdf356f0
DOCKER_PLATFORM_arch := --platform linux/amd64
docker_build = docker build $(DOCKER_PLATFORM_$(1)) --build-arg BASE=$(DOCKER_BASE_$(1)) \
	-t dotfiles-test-$(1) -f test/Dockerfile .

test-docker:
	@echo "Building and running the install + tests in an Ubuntu container..."
	$(call docker_build,ubuntu)
	docker run --rm dotfiles-test-ubuntu

test-docker-arch:
	@echo "Building and running make arch + tests in an Arch Linux container..."
	$(call docker_build,arch)
	docker run $(DOCKER_PLATFORM_arch) --rm dotfiles-test-arch

test-docker-interactive:
	@echo "Starting interactive Ubuntu container..."
	$(call docker_build,ubuntu)
	docker run -it --rm dotfiles-test-ubuntu /bin/bash

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
	@echo "  make init [check=1] - Create the gitignored local files (git/jj identity);"
	@echo "                      check=1 only reports and exits non-zero if unconfigured"
	@echo "  make doctor       - Run health check"
	@echo "  make update       - Update all packages"
	@echo "  make backup       - Backup configurations"
	@echo "  make firefox [profiles=all] [copy=1] [dry=1] - Install user.js into"
	@echo "                      the Firefox profiles that read it (bin/firefox-user-js status"
	@echo "                      reports where it landed)"
	@echo "  make restore [backup=/path] - Restore latest/specified backup snapshot"
	@echo "  make restore-zshenv - Same as unlink: undo links, restore the pre-link .zshenv"
	@echo "  make bench-shell [runs=7] [budget=900] - Benchmark zsh startup budget"
	@echo "  make daily        - Run core pre-push checks (shell, docs, tests)"
	@echo "  make worktree-add name=<task> [base=main] - New isolated worktree"
	@echo "  make worktree-list - List worktrees"
	@echo "  make worktree-remove name=<task> [force=1] - Remove worktree"
	@echo "  make worktree-prune - Prune stale worktree metadata"
	@echo "  make clean        - Remove broken symlinks"
	@echo "  make test-setup   - Install test dependencies (bats)"
	@echo "  make test         - Run test suite"
	@echo "  make test-docker  - Link + run test suite in an Ubuntu container"
	@echo "  make test-docker-arch - make arch (full pacmanfile) + test suite in an Arch container"
	@echo "  make verify       - Run full repository verification"
	@echo "  make verify-config-live - Check tracked configs are actually honoured"
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
	@echo "  SKIP_DOCKER=1           - Skip both container tests in make verify"
	@echo "  SKIP_ARCH_DOCKER=1      - Skip only the Arch container (slow under"
	@echo "                          amd64 emulation on Apple Silicon; CI still runs it)"
	@echo "  SKIP_LINTERS=1          - Skip shellcheck/markdownlint in make verify"
	@echo "  GIT_USER_NAME=...       - Git identity for make init (else it prompts)"
	@echo "  GIT_USER_EMAIL=...      - Git email for make init"
	@echo "  GIT_SIGNING_KEY=...     - Optional GPG signing key for make init"
	@echo "  JJ_USER_NAME=...        - jj identity for make init (defaults to GIT_USER_NAME)"
	@echo "  JJ_USER_EMAIL=...       - jj email for make init (defaults to GIT_USER_EMAIL)"
	@echo ""
	@echo "See README.md for full documentation."
