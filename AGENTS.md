# AGENTS.md

Personal dotfiles for macOS and Arch (incl. Omarchy): zsh + Starship, stowed `.config/`, Homebrew/pacman manifests, BATS tests.

- Commands and daily operations → [OPERATING.md](OPERATING.md)
- Conventions (style, tests, commits, PRs) → [OPERATING.md#contributing-and-conventions](OPERATING.md#contributing-and-conventions)
- Why each tool exists → the comment on its manifest line, `dotfiles-why <tool>` ([install/README.md](install/README.md))

Hard rule: run `make verify` before pushing. CI runs the same suite plus a full fresh-machine install on macOS 14/15 and Ubuntu.
