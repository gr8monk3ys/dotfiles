# Onboarding Docs Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Consolidate the five overlapping top-level docs into three (plus a pointer-form `CLAUDE.md`) so that future-you on a fresh machine and AI assistants opening the repo have one unambiguous source of truth.

**Architecture:** Add one new operator-focused doc (`OPERATING.md`) that absorbs the useful content from `SETUP.md` and `CLAUDE.md`. Reduce `CLAUDE.md` to a 10-line pointer. Merge `CONTRIBUTING.md` into `AGENTS.md`. Delete `SETUP.md` and `CONTRIBUTING.md`. Light edits to `README.md` to add a prominent signpost and strip stale `NEW` tags.

**Tech Stack:** Markdown only. Verification via `make verify` (shell syntax, stale-reference checks, doc-link validator, BATS tests, Nix flake check).

**Spec:** [`docs/superpowers/specs/2026-04-04-onboarding-docs-redesign.md`](../specs/2026-04-04-onboarding-docs-redesign.md)

---

## File Structure

**Created:**
- `OPERATING.md` — new single source of truth for operators and AI assistants (~300 lines)

**Modified:**
- `README.md` — add signpost callout, strip NEW tags, update Documentation table
- `AGENTS.md` — absorb CONTRIBUTING.md content, add cross-link to OPERATING.md, add per-config README convention
- `CLAUDE.md` — reduced to ~10-line pointer file
- `CHANGELOG.md` — one entry under `[Unreleased]`

**Deleted:**
- `SETUP.md`
- `CONTRIBUTING.md`

Each file has one clear job after this change. No content lives in two top-level docs.

---

## Task 1: Create OPERATING.md

**Files:**
- Create: `~/code/dotfiles/OPERATING.md`

- [ ] **Step 1: Verify facts before writing**

Run these commands and confirm outputs match the content below. If any fact drifted, update the relevant section before committing.

```bash
# Should output 24
ls ~/code/dotfiles/.config/ | wc -l

# Should exist and be executable
ls -la ~/code/dotfiles/bin/dotfiles-doctor ~/code/dotfiles/bin/dotfiles-update ~/code/dotfiles/bin/dotfiles-backup

# Should show verify + daily composite targets
grep -E "^verify:|^daily:" ~/code/dotfiles/Makefile

# Machine type is real
grep -n "machine_type" ~/code/dotfiles/.config/zsh/.zshrc
```

Expected: 24 config dirs; three scripts executable; verify + daily targets exist; MACHINE_TYPE export line present in .zshrc.

- [ ] **Step 2: Write OPERATING.md with complete content**

Write the following content verbatim to `~/code/dotfiles/OPERATING.md`:

````markdown
# OPERATING.md

How this repo works — install, daily operations, making changes, troubleshooting.

## Who this is for

Two audiences:

- **Future-you on a fresh machine.** You have full mental context about why things are set up this way, but no muscle memory for which commands to run. This doc is your runbook.
- **AI assistants opening the repo.** You have zero context. This doc gives you orientation, current-state truth, and canonical recipes for changes.

For a public-facing overview (what this repo is and why), see [README.md](README.md). For contributing conventions and style, see [AGENTS.md](AGENTS.md).

---

## Install on a new machine

### Prerequisites (macOS only)

```bash
xcode-select --install
```

### Pick a path

| | Traditional (Homebrew) | Nix |
|---|---|---|
| Reproducibility | Partial — latest versions | Pinned via `flake.lock` |
| Rollback | Manual | Built-in (generations) |
| Cross-platform | macOS focus | Any platform |
| Learning curve | Lower | Higher |
| First-build speed | Faster | Slower (downloads everything) |

**Default recommendation:** Traditional for day-one bootstrap speed; add Nix later if you want version-pinning.

### Path A — Traditional (Homebrew)

One-liner (interactive):

```bash
curl -fsSL https://raw.githubusercontent.com/gr8monk3ys/dotfiles/main/install.sh | bash
```

Non-interactive (CI / repeatable):

```bash
DOTFILES_ASSUME_YES=1 DOTFILES_MACHINE_TYPE=personal DOTFILES_FORCE_PROMPT_STYLE=1 \
  curl -fsSL https://raw.githubusercontent.com/gr8monk3ys/dotfiles/main/install.sh | bash
```

Or clone first and run `make`:

```bash
git clone https://github.com/gr8monk3ys/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
make
```

### Path B — Nix

```bash
git clone https://github.com/gr8monk3ys/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
make nix-install     # installs Nix; restart terminal after
make nix             # applies nix-darwin on macOS
# or:
make nix-home        # applies Home Manager on any platform
```

### Fresh-laptop checklist

After either path completes:

1. **Set machine type:** `echo personal > ~/.machine_type` (or `work` / `server`).
2. **Create local override files** (git-ignored, machine-specific):
   ```bash
   cp ~/.config/zsh/zshrc.local.example ~/.config/zsh/zshrc.local
   cp ~/.config/git/config.local.example ~/.config/git/config.local
   ```
3. **SSH config:** drop any machine-specific snippets into `~/.config/ssh/config.d/`. `make link` ensures `~/.ssh/config` includes that directory.
4. **Run health check:** `make doctor`.
5. **Verify:** `make verify` should pass end-to-end.

---

## Daily operations

Commands you re-run routinely.

| Command | What it does |
|---|---|
| `make link` | Create/refresh all symlinks via Stow. Safe to re-run. |
| `make link-dry-run` | Preview symlink changes without applying. |
| `make doctor` | Comprehensive health check (symlinks, package managers, shell config, tool presence). |
| `make update` | Update all packages (Homebrew, npm, Cargo, Oh My Zsh, plugins). |
| `make backup` | Snapshot configs + package lists. `backup-compress` / `backup-cleanup` variants exist. |
| `make bench-shell` | Benchmark interactive zsh startup against a budget (default 900ms). |
| `make daily` | Fast pre-push check: shell syntax + doc links + tests. |
| `make verify` | Full repo verification: shell syntax + stale-ref check + doc links + tests + nix flake check. |
| `make clean` | Remove broken symlinks in `~/.config/`. |

### Worktree flow (parallel sessions)

For running multiple AI terminals or parallel feature work against the same repo:

```bash
make worktree-add name=<task>         # creates ../dotfiles-<task> on branch ai/<task>
make worktree-list                    # list active worktrees
make worktree-remove name=<task>      # remove worktree by name
make worktree-prune                   # clean up stale metadata
```

### Nix maintenance

```bash
make nix-update   # update flake inputs to latest
make nix          # re-apply (macOS) after updating
make nix-home     # re-apply (any platform) after updating
make nix-gc       # garbage-collect old generations
make nix-check    # validate flake without building
```

---

## Making changes

Canonical recipes. Follow these patterns so new content stays consistent with existing content.

### Add a new app config

```bash
mkdir -p .config/new-app
# Place config files in .config/new-app/
echo "# New App Configuration" > .config/new-app/README.md
make link
```

The `.config/new-app/README.md` should document why the config exists, any non-obvious choices, and a link to upstream docs. This is a repo-wide convention (see [AGENTS.md](AGENTS.md)).

### Add a Homebrew formula (CLI tool)

```bash
brew install <package>
brew bundle dump --force --file=install/Brewfile
```

### Add a Homebrew cask (GUI app)

```bash
brew install --cask <app>
brew bundle dump --force --file=install/Caskfile --cask
```

### Add an npm package

```bash
npm install -g <package>
echo '<package>' >> install/npmfile
```

### Add a Cargo package

```bash
cargo install <package>
echo '<package>' >> install/Rustfile
```

### Add a shell alias

Edit `.config/zsh/aliases.zsh` (~400 lines, organized by tool). Find the relevant section header (e.g., `# --- git ---`) and add the alias there. Reload with `exec zsh`.

### Swap or remove a tool

1. Remove from the install manifest (`install/Brewfile`, `install/Rustfile`, etc.).
2. Remove or replace any `.config/<old-tool>/` directory.
3. Remove its aliases from `.config/zsh/aliases.zsh`.
4. Update `.config/<new-tool>/README.md` if replacing.
5. Update the "Current state" section of this file.
6. Run `make verify`.

### Local overrides (machine-specific, not in git)

- `~/.config/zsh/zshrc.local` — extra env vars, work-only PATH entries, secrets-shaped config.
- `~/.config/git/config.local` — user name/email, signing key.
- `~/.config/ssh/config.d/*.conf` — host-specific SSH snippets.

Both `zshrc.local.example` and `config.local.example` exist as templates.

### Machine profiles

Set `~/.machine_type` to `personal`, `work`, or `server`. On shell startup, `.config/zsh/.zshrc` reads this file into the `MACHINE_TYPE` env var (defaulting to `personal`). Use `MACHINE_TYPE` inside `zshrc.local` to conditionally load work-only tooling, set proxies, etc.

---

## Repo map

Top-level directories, one sentence each.

- **`.config/`** — XDG-compliant app configs (24 directories). Managed by Stow. Each has its own README.
- **`bin/`** — Helper scripts: platform detection, `dotfiles-doctor/update/backup/restore/bench-shell/worktree/nix`, doc-link validator. See `bin/README.md`.
- **`install/`** — Package manifests: `Brewfile`, `Caskfile`, `npmfile`, `Rustfile`, `pacmanfile`, `Codefile` (VSCodium extensions), `duti` (macOS file associations).
- **`test/`** — BATS test suite. Run with `make test`. Pattern: `test_*.bats`, helpers in `test_helper/`.
- **`nix/`** — Nix configs (`home.nix`, `darwin.nix`). Paired with `flake.nix` / `flake.lock` at repo root.
- **`.github/`** — CI workflows (`install.yml`, `test.yml`, `lint.yml`).
- **`docs/`** — Plans and specs for non-trivial changes.

The Stow target is `~/.config/`. The only exception is `.zshenv`, which is manually symlinked from the repo root to `~/.zshenv` because Zsh must find it in `$HOME`.

---

## Current state (primary vs backup)

Which tools are actually in use right now. Update this table when you swap tools.

| Category | Primary | Backup / transitional | Notes |
|---|---|---|---|
| Terminal | Ghostty | — | Zig-based GPU terminal |
| Multiplexer | Zellij | tmux | tmux config kept for SSH/legacy contexts |
| File manager | Yazi | — | lf has been removed |
| Shell | Zsh (+ Zinit) | — | Plugin manager: Zinit; prompt: Powerlevel10k |
| VCS | Jujutsu (`jj`) + Git | Git alone | `jj git init --colocate` for hybrid repos |
| Editor | Neovim | VSCodium | VSCodium for GUI/extension-heavy work |
| Window manager | AeroSpace | — | i3-like tiling for macOS |
| Keyboard remapping | Karabiner | — | macOS |

This table replaces the stale `NEW` tag system that used to live in README.md and CLAUDE.md. "NEW" decays into a lie; "primary vs backup" only changes when you actually swap tools.

---

## Troubleshooting

### Stow symlink conflict

```
WARNING! stowing .config would cause conflicts:
  * existing target is neither a link nor a directory: ...
```

Existing file/dir at the target is blocking Stow. Back it up, then re-link:

```bash
mv ~/.config/<app> ~/.config/<app>.backup
make link
```

### `.zshenv` symlink lost

```bash
make restore-zshenv
```

### Homebrew prefix confusion

- Apple Silicon: `/opt/homebrew`
- Intel: `/usr/local`

The `bin/platform is-arm64` helper detects this. Scripts should use `$(bin/platform select /opt/homebrew /usr/local "bin/platform is-arm64")`, never hardcode.

### Nix `experimental-features` error

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### Shell not loading config

```bash
ls -la ~/.zshenv                          # should be a symlink into the repo
echo $ZDOTDIR                             # should be ~/.config/zsh
source ~/.zshenv && exec zsh              # reload
```

### Broken symlinks in `~/.config/`

```bash
make clean
```

### Doc link validation fails (`make verify-doc-links`)

The validator (`bin/validate-doc-links`) reports the file + line of each bad link. Fix the path or update the link target.

### Stale reference check fails (`make verify-stale-refs`)

`make verify-stale-refs` scans for strings left over from past migrations (old theme names, removed file paths, typos). When it fires, grep for the reported pattern and either update or remove it.

### First Nix build is extremely slow

Expected — it downloads and builds everything from scratch. Subsequent builds use the binary cache and are fast.
````

- [ ] **Step 3: Verify file exists and has expected structure**

```bash
wc -l ~/code/dotfiles/OPERATING.md
grep -c "^## " ~/code/dotfiles/OPERATING.md
grep -c "^### " ~/code/dotfiles/OPERATING.md
```

Expected: roughly 270-320 lines; 7 top-level `## ` section headers; several `### ` sub-section headers.

- [ ] **Step 4: Verify no TODO/TBD placeholders**

```bash
grep -niE "TODO|TBD|FIXME|XXX|placeholder" ~/code/dotfiles/OPERATING.md
```

Expected: no matches. If any appear, fix before committing.

- [ ] **Step 5: Commit**

```bash
cd ~/code/dotfiles
git add OPERATING.md
git commit -m "$(cat <<'EOF'
docs: add OPERATING.md as single source of truth for operators

New top-level doc covering: install paths, daily operations, making
changes, repo map, current state (primary vs backup tools), and
troubleshooting. Audience is future-self on a fresh machine and AI
assistants needing orientation.

Refs: docs/superpowers/specs/2026-04-04-onboarding-docs-redesign.md

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Reduce CLAUDE.md to pointer form

**Files:**
- Modify: `~/code/dotfiles/CLAUDE.md` (full rewrite — 400+ lines → 10 lines)

- [ ] **Step 1: Replace CLAUDE.md content entirely**

Overwrite `~/code/dotfiles/CLAUDE.md` with exactly this content:

```markdown
# CLAUDE.md

This file exists because Claude Code reads it. The real content lives elsewhere:

- **Repo conventions, style, testing, commits** → [AGENTS.md](AGENTS.md)
- **How this repo works (install, daily ops, troubleshooting)** → [OPERATING.md](OPERATING.md)
- **Public-facing overview** → [README.md](README.md)

Keep this file minimal. All other top-level docs consolidate into the three above.
```

- [ ] **Step 2: Verify size and links**

```bash
wc -l ~/code/dotfiles/CLAUDE.md
grep -c "AGENTS.md\|OPERATING.md\|README.md" ~/code/dotfiles/CLAUDE.md
```

Expected: ≤15 lines; 3 link references (one per pointer).

- [ ] **Step 3: Commit**

```bash
cd ~/code/dotfiles
git add CLAUDE.md
git commit -m "$(cat <<'EOF'
docs: reduce CLAUDE.md to a pointer file

The real content now lives in AGENTS.md (conventions) and OPERATING.md
(how the repo works). Claude Code still reads this file, so we keep it
as a stable entry point that routes to the canonical sources. Satisfies
Claude Code's convention with near-zero maintenance cost.

Refs: docs/superpowers/specs/2026-04-04-onboarding-docs-redesign.md

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Expand AGENTS.md

**Files:**
- Modify: `~/code/dotfiles/AGENTS.md`

Three specific changes: absorb CONTRIBUTING.md content, add cross-link to OPERATING.md at the top, add a per-config README convention section.

- [ ] **Step 1: Read current AGENTS.md to preserve structure**

```bash
cat ~/code/dotfiles/AGENTS.md
```

The file currently has these section headers (in order):
1. `## Project Structure & Module Organization`
2. `## Build, Test, and Development Commands`
3. `## Coding Style & Naming Conventions`
4. `## Testing Guidelines`
5. `## Commit & Pull Request Guidelines`
6. `## Security & Local Overrides`

- [ ] **Step 2: Add cross-link to OPERATING.md at top of file**

Use Edit to insert a reference line right after the `# Repository Guidelines` H1 heading.

Find: `# Repository Guidelines\n\n## Project Structure & Module Organization`

Replace with:

```
# Repository Guidelines

For install, daily operations, and troubleshooting, see [OPERATING.md](OPERATING.md). This file covers style, testing, and contribution conventions.

## Project Structure & Module Organization
```

- [ ] **Step 3: Merge CONTRIBUTING.md into the "Commit & Pull Request Guidelines" section**

Current CONTRIBUTING.md content:

```
# Contributing

## Workflow
1. Create a feature branch from the default branch.
2. Keep changes focused and small.
3. Add or update tests when behavior changes.
4. Open a pull request with context and validation steps.

## Pull Request Checklist
- Code builds or runs locally
- Tests pass locally
- Docs updated when needed
- No secrets or credentials committed

## Commit Style
Use clear commit messages describing intent and scope.
```

The existing AGENTS.md section already covers most of this. Replace the current `## Commit & Pull Request Guidelines` section with this merged version:

```markdown
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
```

- [ ] **Step 4: Add "Per-config README convention" section**

Append a new section at the end of AGENTS.md (after `## Security & Local Overrides`):

```markdown

## Per-Config README Convention

Every `.config/<app>/` directory should contain a `README.md` that documents:

- Why this app is installed and what role it fills (primary vs backup vs specialized).
- Any non-obvious configuration choices (keybindings, overrides, custom themes).
- A link to the upstream docs or project page.

This is aspirational for existing configs and required for new ones. When adding a `.config/<app>/` directory, create its README in the same commit.
```

- [ ] **Step 5: Verify edits**

```bash
grep -n "OPERATING.md" ~/code/dotfiles/AGENTS.md
grep -n "^## " ~/code/dotfiles/AGENTS.md
grep -c "Per-Config README Convention" ~/code/dotfiles/AGENTS.md
```

Expected: 1 match for `OPERATING.md` at the top; 7 top-level `## ` headers (was 6, now 7 with the new convention section); 1 match for the new section title.

- [ ] **Step 6: Commit**

```bash
cd ~/code/dotfiles
git add AGENTS.md
git commit -m "$(cat <<'EOF'
docs: expand AGENTS.md, absorb CONTRIBUTING.md

- Add cross-link to OPERATING.md at top.
- Merge CONTRIBUTING.md's workflow and PR checklist into the existing
  Commit & Pull Request Guidelines section.
- Add Per-Config README convention section.

CONTRIBUTING.md is now redundant and will be deleted in a follow-up
commit.

Refs: docs/superpowers/specs/2026-04-04-onboarding-docs-redesign.md

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Update README.md

**Files:**
- Modify: `~/code/dotfiles/README.md`

Four specific changes: add signpost callout, strip NEW tags, update Documentation table, remove deleted-doc references.

- [ ] **Step 1: Add "Working on this repo?" callout after Quick Start**

Find the closing `---` separator immediately after the Quick Start section (after the `Prerequisites (macOS)` collapsible block, before `## ✨ Features`).

Replace:

```
</details>

---

## ✨ Features
```

With:

```
</details>

---

> **Working on this repo?** If you're future-you on a new machine or an AI assistant needing to make changes, read **[OPERATING.md](OPERATING.md)** — install paths, daily commands, making changes, repo map, and troubleshooting. For conventions and style, see **[AGENTS.md](AGENTS.md)**.

---

## ✨ Features
```

- [ ] **Step 2: Strip all NEW tags from the README**

Use a grep pass first to locate them:

```bash
grep -nE "\(NEW\)|NEW$|\*\*NEW\*\*" ~/code/dotfiles/README.md
```

Then remove each occurrence. Known locations based on current README:

- Features table: "Ghostty - Zig-based GPU terminal with built-in splits (primary) **(NEW)**" → strip `**(NEW)**`
- Features table: "Zellij - Modern multiplexer **(NEW)**" → strip
- Features table: "yazi - Blazing fast file manager **(NEW)**" → strip
- Features table: "broot - Tree with fuzzy search **(NEW)**" → strip
- Features table: "navi - Interactive cheatsheets **(NEW)**" → strip
- Features table: "ouch - Universal archives **(NEW)**" → strip
- Features table: "Jujutsu (jj) - Next-gen Git **(NEW)**" → strip
- Structure tree: `# Terminal emulator (NEW)` → strip `(NEW)`
- Structure tree: `# File manager (NEW)` → strip
- Structure tree: `# Jujutsu VCS (NEW)` → strip
- Structure tree: `# Terminal multiplexer (NEW)` → strip
- Structure tree: `# Nix configuration (NEW)` → strip

Use `sed` or Edit with `replace_all` to strip the exact token pattern `**(NEW)**` and ` (NEW)`:

```bash
cd ~/code/dotfiles
# Remove bold-wrapped variant (may appear after text)
sed -i '' 's/ \*\*(NEW)\*\*//g' README.md
# Remove plain parenthetical variant
sed -i '' 's/ (NEW)//g' README.md
```

Then re-verify:

```bash
grep -nE "\(NEW\)|NEW$|\*\*NEW\*\*" ~/code/dotfiles/README.md
```

Expected: no matches.

- [ ] **Step 3: Update Documentation table**

Find the current Documentation table:

```
| Document | Description |
|----------|-------------|
| [CLAUDE.md](CLAUDE.md) | AI assistant guide |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contribution guidelines |
| [CHANGELOG.md](CHANGELOG.md) | Version history |
```

Replace with:

```
| Document | Description |
|----------|-------------|
| [OPERATING.md](OPERATING.md) | Install, daily ops, making changes, troubleshooting |
| [AGENTS.md](AGENTS.md) | Conventions, style, testing, PR checklist |
| [CHANGELOG.md](CHANGELOG.md) | Version history |
```

(Removes the stale CLAUDE.md entry since it's now a pointer file, and removes CONTRIBUTING.md since it's being deleted in Task 5.)

- [ ] **Step 4: Verify README edits**

```bash
grep -c "OPERATING.md" ~/code/dotfiles/README.md
grep -c "AGENTS.md" ~/code/dotfiles/README.md
grep -nE "\(NEW\)|\*\*NEW\*\*" ~/code/dotfiles/README.md
grep -c "CONTRIBUTING.md" ~/code/dotfiles/README.md
```

Expected: OPERATING.md mentioned ≥2 times (callout + doc table); AGENTS.md mentioned ≥2 times; zero NEW tags; zero CONTRIBUTING.md references.

- [ ] **Step 5: Commit**

```bash
cd ~/code/dotfiles
git add README.md
git commit -m "$(cat <<'EOF'
docs: add OPERATING.md signpost to README, strip stale NEW tags

- Add prominent "Working on this repo?" callout after Quick Start,
  pointing to OPERATING.md and AGENTS.md.
- Strip all NEW tags (Features table + Structure diagram). Current-state
  truth now lives in OPERATING.md's primary-vs-backup section instead.
- Update Documentation table: remove CLAUDE.md (now a pointer) and
  CONTRIBUTING.md (being deleted), add OPERATING.md and AGENTS.md.

Refs: docs/superpowers/specs/2026-04-04-onboarding-docs-redesign.md

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Delete SETUP.md and CONTRIBUTING.md

**Files:**
- Delete: `~/code/dotfiles/SETUP.md`
- Delete: `~/code/dotfiles/CONTRIBUTING.md`

- [ ] **Step 1: Check for remaining references before deleting**

```bash
cd ~/code/dotfiles
grep -rln --exclude-dir=.git --exclude-dir=docs "SETUP\.md\|CONTRIBUTING\.md" . 2>&1
```

Expected: zero or only matches inside the `docs/superpowers/` directory (specs/plans may reference them, which is fine — those are historical records).

If any *live* references remain (outside `docs/superpowers/`), fix them before deletion. Known candidates to check: README.md (should be clean after Task 4), AGENTS.md (no existing refs expected), any workflow files.

- [ ] **Step 2: Delete the files**

```bash
cd ~/code/dotfiles
git rm SETUP.md CONTRIBUTING.md
```

- [ ] **Step 3: Verify deletion**

```bash
ls ~/code/dotfiles/SETUP.md 2>&1
ls ~/code/dotfiles/CONTRIBUTING.md 2>&1
```

Expected: both commands report "No such file or directory".

- [ ] **Step 4: Commit**

```bash
cd ~/code/dotfiles
git commit -m "$(cat <<'EOF'
docs: delete SETUP.md and CONTRIBUTING.md after consolidation

SETUP.md's install-path and Nix content now lives in OPERATING.md.
CONTRIBUTING.md's workflow and PR checklist now live in AGENTS.md.

Refs: docs/superpowers/specs/2026-04-04-onboarding-docs-redesign.md

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Update CHANGELOG.md

**Files:**
- Modify: `~/code/dotfiles/CHANGELOG.md`

- [ ] **Step 1: Read current CHANGELOG structure**

```bash
head -30 ~/code/dotfiles/CHANGELOG.md
```

Note the `[Unreleased]` section header format. Typical "Keep a Changelog" format uses `## [Unreleased]` with subheadings `### Added`, `### Changed`, `### Removed`.

- [ ] **Step 2: Add new entry under [Unreleased]**

Locate the `## [Unreleased]` section. Insert the following (merging into existing `### Added`, `### Changed`, `### Removed` subsections if they already exist; creating them if not):

```markdown
### Added
- `OPERATING.md`: single source of truth for operators and AI assistants (install paths, daily commands, making changes, repo map, current-state table, troubleshooting).

### Changed
- Consolidated top-level documentation. `CLAUDE.md` reduced to a pointer file. `AGENTS.md` absorbed `CONTRIBUTING.md`'s workflow and PR checklist, and gained a per-config README convention. `README.md` got an `OPERATING.md` signpost; all stale `NEW` tags removed.

### Removed
- `SETUP.md` (content folded into `OPERATING.md`).
- `CONTRIBUTING.md` (content folded into `AGENTS.md`).
```

- [ ] **Step 3: Verify entry**

```bash
grep -c "OPERATING.md" ~/code/dotfiles/CHANGELOG.md
grep -A 20 "## \[Unreleased\]" ~/code/dotfiles/CHANGELOG.md | head -25
```

Expected: at least 2 mentions of OPERATING.md; visible new entries under [Unreleased].

- [ ] **Step 4: Commit**

```bash
cd ~/code/dotfiles
git add CHANGELOG.md
git commit -m "$(cat <<'EOF'
docs: log doc consolidation in CHANGELOG

Refs: docs/superpowers/specs/2026-04-04-onboarding-docs-redesign.md

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: Run verification and fix any broken doc links

**Files:**
- Potentially modify any file with broken links, depending on findings.

- [ ] **Step 1: Run the doc-link validator**

```bash
cd ~/code/dotfiles
make verify-doc-links 2>&1
```

Expected: "Validating markdown links..." followed by clean exit (exit code 0).

If broken links are reported, they are likely from other files still linking to deleted `SETUP.md` or `CONTRIBUTING.md`, or from the pointer `CLAUDE.md` / new `OPERATING.md` linking to something that doesn't exist.

- [ ] **Step 2: Run the stale-reference check**

```bash
cd ~/code/dotfiles
make verify-stale-refs 2>&1
```

Expected: "Checking for stale migration references..." with no stale pattern matches. If matches are found, the validator prints the line and file; fix each one.

- [ ] **Step 3: Run the full verify target**

```bash
cd ~/code/dotfiles
make verify 2>&1
```

Expected: all five subchecks pass — shell syntax, stale refs, doc links, tests, Nix flake check. The final line should be `✓ Verification complete`.

**Known caveat:** the repo's working tree already had uncommitted shell/config changes at the time this plan was written (see git status on branch `main` at spec time). Any pre-existing test or shell failures unrelated to doc changes are **not** this plan's responsibility. Only fix failures that were introduced by this plan's commits.

To isolate plan-caused failures from pre-existing ones, check whether the failure mentions a file this plan touched (`README.md`, `AGENTS.md`, `CLAUDE.md`, `OPERATING.md`, `CHANGELOG.md`, `SETUP.md`, `CONTRIBUTING.md`). If not, it's pre-existing.

- [ ] **Step 4: If fixes were required, commit them**

```bash
cd ~/code/dotfiles
git status
# Stage only files this plan is responsible for
git add <files>
git commit -m "$(cat <<'EOF'
docs: fix link and reference fallout from doc consolidation

Refs: docs/superpowers/specs/2026-04-04-onboarding-docs-redesign.md

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

If no fixes were required, skip this step.

- [ ] **Step 5: Confirm git log shows the expected commits**

```bash
cd ~/code/dotfiles
git log --oneline -n 10
```

Expected: the commits from Tasks 1-6 (and optionally 7) should appear at the top of the log, all prefixed with `docs:`.

---

## Done

At this point:

- `OPERATING.md` exists as the canonical operator doc.
- `CLAUDE.md` is a 10-line pointer.
- `AGENTS.md` absorbed `CONTRIBUTING.md` + has the per-config README convention.
- `README.md` points at `OPERATING.md` and has zero `NEW` tags.
- `SETUP.md` and `CONTRIBUTING.md` are deleted.
- `CHANGELOG.md` records the consolidation.
- `make verify` passes (or has only pre-existing failures unrelated to this plan).

The success criteria from the spec can be checked:

- ✅ A reader can find routing within 30 seconds (README callout is unavoidable).
- ✅ `README.md` has a single unambiguous pointer to `OPERATING.md`.
- ✅ No content lives in two top-level docs.
- ✅ No `NEW` tags remain in `README.md` or `CLAUDE.md`.
- ✅ No references to deleted scripts or stale counts in live docs.
- ✅ `make verify` passes for this plan's changes.
- ✅ `CLAUDE.md` is ≤15 lines and contains no standalone facts.
