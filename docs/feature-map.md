# Feature map

What a user can reach in this checkout, in the user's words. Each row was run
from a clean `HOME` on Arch; the last column is the command and what it
printed. Commands that change the machine are listed by their `--help`, or by
the dry run they default to.

| Feature | Where | How to reach it | How to check it works |
|---|---|---|---|
| Install everything for this OS | `Makefile` | `make` (`make macos`, `make arch`, `make linux`) | `make -n` prints the steps for the detected platform |
| Detect the platform | `bin/platform` | `bin/platform detect` | prints `macos`, `arch`, `linux` or `unknown` (`arch` here) |
| Preview linking configs into `$HOME` | `bin/dotfiles-link` | `make link-dry-run` or `bin/dotfiles-link` | starts `Dry run: nothing will change.`, lists `would link ...` lines, exit 0 |
| Link / unlink configs | `bin/dotfiles-link` | `make link`, `make unlink` | a second `make link` reports `Everything already in place.` (changes `$HOME`; not run here) |
| Set up local git/jj identity | `bin/dotfiles-init` | `make init` | `make init check=1` exits 1 and names each unconfigured file |
| Health check | `bin/dotfiles-doctor` | `make doctor` | ends with a `Summary` of issues and warnings; exit 1 when an issue is found |
| Ask why a tool is installed | `bin/dotfiles-why` | `bin/dotfiles-why git` | prints the `docs/TOOLS.md` entry for git |
| Isolated worktree per task | `bin/dotfiles-worktree` | `make worktree-add name=<task>`, `worktree-list`, `worktree-remove`, `worktree-prune` | `bin/dotfiles-worktree list` prints `path sha [branch]` per worktree |
| Back up current configs | `bin/dotfiles-backup` | `make backup` (`-c` compress, `-C` clean up old) | `bin/dotfiles-backup --help` (writes into `$HOME`; not run here) |
| Restore a backup | `bin/dotfiles-restore` | `make restore [backup=/path]` | `bin/dotfiles-restore --help` (not run here) |
| Update packages and the repo | `bin/dotfiles-update` | `make update` (`--skip-brew`, `--skip-npm`, `--skip-cargo`) | `bin/dotfiles-update --help` (not run here) |
| Unattended pull on macOS | `bin/dotfiles-sync` | `make sync-install`, `sync-status`, `sync-run`, `sync-uninstall` | macOS only (`osascript`, `launchctl`); fails with `osascript: command not found` on Arch |
| Zsh startup budget | `bin/dotfiles-bench-shell` | `make bench-shell [runs=7] [budget=900]` | `PASS: average startup 10ms is within budget 900ms` |
| Claude Code plugins, MCP servers, hooks | `bin/claude-sync` | `make claude-sync [apply=1] [only=...]` | dry run prints `would   claude plugin marketplace add ...` |
| Claude Code themes | `bin/claude-themes` | `make claude-themes [copy=1] [dry=1]` | `bin/claude-themes status` prints `absent<TAB>path` per theme |
| Firefox `user.js` | `bin/firefox-user-js` | `make firefox [profiles=all] [copy=1] [dry=1]` | `bin/firefox-user-js status` names the missing `profiles.ini` when Firefox has none |
| Hermes Agent on local Ollama | `bin/hermes-offline` | `make hermes-offline [apply=1] [pull=1]` | dry run prints `would   hermes config set model.provider custom` |
| Omarchy rice and desktop settings | `omarchy/setup.sh` | `make omarchy [apply=1] [only=<step>] [rice=<name>]` | dry run starts `Dry run: nothing will change.`, then `rice: field-notebook` and an `ok`/`would` line per package |
| Render rice themes from one template | `bin/rice-themes` | `bin/rice-themes render`, `check`, `list` | `check` exits 0 when every committed output is current |
| Desktop wallpaper | `bin/wallpaper` | `bin/wallpaper` | `bin/wallpaper --help` (downloads a scan; not run here) |
| Merge a green PR | `bin/gh-merge-green`, `bin/gh-merge-local-green` | `bin/gh-merge-green <pr>` | prints its usage line with no arguments (merges on GitHub; not run here) |
| Alias check | `bin/check-alias-references` | `bin/check-alias-references` | `all aliases resolve` |
| Tool catalog check | `bin/validate-tool-docs` | `make verify-tool-docs` | `Tool catalog is in sync with install manifests.` |
| Doctor tool list check | `bin/validate-doctor-tools` | `make verify-doctor-tools` | `dotfiles-doctor tool lists are in sync with install manifests.` |
| Markdown link check | `bin/validate-doc-links` | `make verify-doc-links` | `Markdown links are valid.` |
| Verification report | `bin/ci-summary` | `bin/ci-summary` on a `make verify` log | `bin/ci-summary --help` |
| Everything CI checks | `Makefile` | `make verify` (`SKIP_DOCKER=1`, `SKIP_LINTERS=1`) | exits non-zero if any part fails |
| Test suites | `test/` | `make test`, `make test-docker`, `make test-docker-arch` | BATS summary |
