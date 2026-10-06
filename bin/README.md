# bin/

Every script answers `--help` with its usage and the reasoning behind it;
this page is only the index. Most are wrapped by a `make` target
([OPERATING.md](../OPERATING.md#daily-operations)). The domain terms in
_italics_ are defined in [CONTEXT.md](../CONTEXT.md).

## Scripts

| Script | What it is for |
| --- | --- |
| [`platform`](platform) | OS and architecture detection; the one place that branches on the OS (_Platform_) |
| [`link`](link) | Links the checkout into a home directory: apply, dry-run, undo (_Link_) |
| [`link-state`](link-state) | Classifies every managed path; doctor reports it, `make clean` acts on it (_Link state_) |
| [`manifest`](manifest) | The only reader of `install/`: package lists, rationale, `cmd=` and `tier=` (_Manifest_) |
| [`install-kind`](install-kind) | Install, update or record one manifest _kind_ |
| [`palette`](palette) | Render and check every themed file from `.config/palette/` (_Palette_) |
| [`wallpaper`](wallpaper) | Fetch _La Danse_ and compose the desktop background from the palette |
| [`dotfiles-init`](dotfiles-init) | Write the gitignored identity files `make` cannot (_Local config_) |
| [`dotfiles-doctor`](dotfiles-doctor) | Health check: one _reporter_ over every classifier |
| [`dotfiles-update`](dotfiles-update) | Fast-forward the checkout, update every kind, then zinit and Neovim plugins |
| [`dotfiles-sync`](dotfiles-sync) | Unattended fast-forward for launchd, with macOS notifications (_Sync state_) |
| [`dotfiles-backup`](dotfiles-backup) | Write a _snapshot_ of configs and installed packages |
| [`dotfiles-restore`](dotfiles-restore) | Replay a snapshot's config trees |
| [`dotfiles-why`](dotfiles-why) | Print why a package is installed, from its manifest line |
| [`dotfiles-bench-shell`](dotfiles-bench-shell) | Time interactive zsh startup against a budget |
| [`dotfiles-worktree`](dotfiles-worktree) | Create and remove git worktrees for parallel sessions |
| [`firefox-user-js`](firefox-user-js) | Put `user.js` in the Firefox profiles that read it (_Firefox profile state_) |
| [`check-alias-references`](check-alias-references) | Fail on an unconditional alias whose command nothing installs |
| [`validate-doc-links`](validate-doc-links) | Fail on a Markdown link to a file that does not exist |
| [`validate-config-live`](validate-config-live) | Ask each tool whether it actually reads its tracked config |

## lib/

Sourced, never run. Each file's header has its usage.

- [`preamble.sh`](lib/preamble.sh) — `DOTFILES_DIR`, `command_exists`,
  `knob_on` (the one truthiness rule for boolean env knobs) and `as_root`.
- [`ui.sh`](lib/ui.sh) — `print_header/success/info/warn/error`: plain ANSI,
  gum-styled headers on a terminal that has gum.
- [`git-sync.sh`](lib/git-sync.sh) — the fast-forward state machine behind
  _sync state_.
- [`snapshot.sh`](lib/snapshot.sh) — the snapshot layout, read by backup and
  restore.

## Writing a script

- Bash, `set -euo pipefail`, kebab-case name. Start with the two lines every
  script shares, since `SCRIPT_DIR` cannot live in the file it locates:

  ```bash
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "$SCRIPT_DIR/lib/preamble.sh"
  ```

- Operate on `DOTFILES_DIR`, never on the script's own location, so tests can
  point it at a fixture. Resolve sibling tools from `SCRIPT_DIR`.
- Answer `--help` from the header comment; `test_bin_scripts.bats` runs it on
  every file here. `make lint` shellchecks them all.
- Portable shell only: macOS ships BSD userland. OS differences go behind
  `platform`, not inline.
- Tests go in `test/test_<script>.bats` ([test/README.md](../test/README.md)).
