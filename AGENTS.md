# Repository Guidelines

## Project Structure & Module Organization
This repository is organized by responsibility:
- `.config/` contains XDG app configs (`ghostty/`, `nvim/`, `zsh/`, `git/`, `aerospace/`, etc.). Keep tool-specific changes inside the matching directory.
- `bin/` holds portable helper scripts (health checks, backup, sync, templating, secrets, link validation).
- `install/` stores package manifests (`Brewfile`, `Caskfile`, `npmfile`, `Rustfile`, `pacmanfile`, `Codefile`, `duti`).
- `test/` contains BATS tests and helpers (`test_helper/common.bash`).
- `nix/` plus `flake.nix`/`flake.lock` define reproducible Nix setups.
- `cmd/dotfiles/` is the Go CLI entrypoint.

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
Testing is BATS-based (`test/*.bats`). Add or update tests whenever behavior changes, especially regression guards in `test/test_regressions.bats`. Run `make test` locally before opening a PR; use targeted runs like `bats test/test_regressions.bats -f "theme consistency"` when iterating.

## Commit & Pull Request Guidelines
Commit style in history is Conventional Commit-like (`feat:`, `fix:`, `chore:`, optional scope). Keep changes focused and small. PRs should include:
- what changed and why,
- validation steps/commands run (for example, `make verify`),
- doc updates when behavior or commands change,
- confirmation that no secrets were committed.

## Security & Local Overrides
Never commit secrets. Use `dotfiles-secrets` workflows and keep machine-specific overrides in local files (for example, `~/.config/zsh/zshrc.local`, `~/.config/git/config.local`).
