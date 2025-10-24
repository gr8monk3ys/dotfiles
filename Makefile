DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
OS := $(shell bin/is-supported bin/is-macos macos $(shell bin/is-supported bin/is-arch arch linux))
HOMEBREW_PREFIX := $(shell bin/is-supported bin/is-arm64 /opt/homebrew /usr/local)
export N_PREFIX = $(HOME)/.n
PATH := $(HOMEBREW_PREFIX)/bin:$(DOTFILES_DIR)/bin:$(N_PREFIX)/bin:$(PATH)
SHELL := env PATH=$(PATH) /bin/bash
SHELLS := /private/etc/shells
BIN := $(HOMEBREW_PREFIX)/bin
export XDG_CONFIG_HOME = $(HOME)/.config
export STOW_DIR = $(DOTFILES_DIR)
export ACCEPT_EULA=Y

.PHONY: test

all: $(OS)

macos: sudo core-macos packages-macos link duti bun

arch: core-arch packages-arch link

core-macos: brew bash git npm

core-arch:
	pacman -Syu --noconfirm

stow-arch: core-arch
	is-executable stow || pacman -S --noconfirm stow

stow-macos: brew
	is-executable stow || brew install stow

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
	for EXT in $$(cat install/Codefile); do code --install-extension $$EXT; done

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

.PHONY: doctor update backup backup-compress backup-cleanup clean restore brew-update brew-cleanup
