# Repository Guidelines

For install, daily operations, and troubleshooting, see [OPERATING.md](OPERATING.md). This file covers style, testing, and contribution conventions.

## Project Structure & Module Organization
This repository is organized by responsibility:
- `.config/` contains XDG app configs (`ghostty/`, `nvim/`, `zsh/`, `git/`, `aerospace/`, etc.). Keep tool-specific changes inside the matching directory.
- `bin/` holds portable helper scripts (health checks, backup, sync, templating, secrets, link validation).
- `install/` stores package manifests (`Brewfile`, `Caskfile`, `npmfile`, `Rustfile`, `pacmanfile`, `Codefile`, `duti`).
- `test/` contains BATS tests and helpers (`test_helper/common.bash`).
- `nix/` plus `flake.nix`/`flake.lock` define reproducible Nix setups.


## Build, Test, and Development Commands
Use `make help` to see all targets. Core commands:
- `make` - full install for detected OS.
- `make link` / `make unlink` - create/remove symlinks.
- `make link-dry-run` - preview stow changes safely.
- `make test-setup` - install BATS dependencies.
- `make test` - run BATS suite.
- `make verify` - run shell checks, stale-reference checks, doc-link checks, tests, and Nix checks.
- `make nix`, `make nix-home`, `make nix-update` - apply/update Nix configs.

## Coding Style & Naming Conventions
Follow `.editorconfig`:
- UTF-8, LF, final newline, no trailing whitespace.
- Default indentation: 2 spaces.
- Shell scripts: 4 spaces.
- Makefiles: tabs only.
- Markdown: keep lines readable (configured max length 80).
Prefer portable shell patterns (avoid GNU-only flags in scripts sourced on macOS). Name executables and helpers in kebab-case (example: `dotfiles-update`). Add new tests as `test/test_*.bats`.

## Testing Guidelines
Testing is BATS-based (`test/*.bats`). Add or update tests whenever behavior changes, especially regression guards in `test/test_regressions.bats`. Run `make test` locally before opening a PR; use targeted runs like `bats test/test_regressions.bats -f "theme consistency"` when iterating. The suite includes shell-surface validation (`make verify-shell-surface`) which parses and sources `.zshenv`, `aliases.zsh`, and `functions.zsh`, asserts sentinel aliases per conditional block, and runs `bin/check-alias-references` to verify every unconditional alias references a known command.

## Commit & Pull Request Guidelines

Commit style in history is Conventional Commit-like (`feat:`, `fix:`, `chore:`, optional scope). Keep commits focused and small with clear messages describing intent and scope.

### Workflow

1. Create a feature branch from the default branch.
2. Keep changes focused and small.
3. Add or update tests when behavior changes.
4. Open a pull request with context and validation steps.

### Pull Request Checklist

- Code builds or runs locally
- Tests pass locally (`make test`) and `make verify` succeeds
- Docs updated when behavior or commands change
- No secrets or credentials committed

## Security & Local Overrides
Never commit secrets. Keep machine-specific overrides in local files (for example, `~/.config/zsh/zshrc.local`, `~/.config/git/config.local`).

## Per-Config README Convention

Every `.config/<app>/` directory should contain a `README.md` that documents:

- Why this app is installed and what role it fills (primary vs backup vs specialized).
- Any non-obvious configuration choices (keybindings, overrides, custom themes).
- A link to the upstream docs or project page.

This is aspirational for existing configs and required for new ones. When adding a `.config/<app>/` directory, create its README in the same commit.

## Tool Catalog Convention

Every package in the install manifests must have an entry in
[docs/TOOLS.md](docs/TOOLS.md) explaining why it is part of the stack
(`bin/validate-tool-docs`, run by `make verify`, enforces this in both
directions — undocumented packages and stale entries fail verification).
When adding or removing a package, update the catalog in the same commit.
Browse it interactively with `dotfiles-why`.
