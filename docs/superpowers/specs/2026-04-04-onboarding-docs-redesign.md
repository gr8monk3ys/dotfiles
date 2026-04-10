# Onboarding Docs Redesign

**Date:** 2026-04-04
**Status:** Design
**Owner:** Lorenzo (gr8monk3ys)

## Problem

The repository has five overlapping top-level documentation files (`README.md`, `SETUP.md`, `CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md`) that collectively fail a new reader — where "new reader" is defined as one of two audiences the owner actually cares about:

- **Audience A (primary):** Future-self arriving at a fresh machine. Has full mental context but no muscle memory for what's changed. Needs accurate routing and fast bootstrap.
- **Audience D (secondary):** AI assistants opening the repo for the first time. Has zero context. Needs orientation, conventions, and current-state truth.

Specific failures the current docs exhibit:

1. **No reading order.** Five top-level docs, no "start here" signpost. Readers guess.
2. **Redundancy.** `README.md` and `SETUP.md` both cover install paths. `CLAUDE.md` and `AGENTS.md` both cover conventions. `CONTRIBUTING.md` (16 lines) is a subset of `AGENTS.md`.
3. **Stale content in CLAUDE.md.** Claims 21 `.config/` directories (there are 24); references deleted scripts (`bin/dotfiles-secrets`, `bin/dotfiles-template`); contradicts itself on tmux vs Zellij primacy; contains changelog-style artifacts ("26+ TODO items completed", "5000+ lines added").
4. **"NEW" tags that aren't new.** Ghostty, Yazi, Zellij, jj, and Nix are all badged NEW in both `README.md` and `CLAUDE.md`, but have been stable for months. Stale freshness markers train readers to distrust the docs.
5. **README is written for a third audience.** It's a public-facing marketing page (banner, badges, feature tables, credits) — fine for GitHub visitors, but not what either Audience A or D actually needs.

The core issue is **structural**, not content-level. Facts live in multiple places, so each can go stale independently. Consolidation is the fix.

## Non-Goals

- **No screenshots.** Neither audience benefits from them.
- **No audit of the 24 per-config READMEs.** Scoped out; separate future task.
- **No invented "how Lorenzo works day-to-day" narrative.** Only content verifiable from the repo. Personal workflow narrative is ground truth only the owner has.
- **No rewrite of `README.md`'s marketing skin.** Light edits only. The banner, feature tables, FAQ, troubleshooting, and credits stay.
- **No CHANGELOG restructure.** One entry noting the doc restructure, nothing more.

## Target State: Top-Level Doc Set

Five top-level docs collapse to three, plus a small pointer file:

| File | Action | Single job |
|---|---|---|
| `README.md` | Keep (light edits) | Public face for GitHub visitors. |
| `AGENTS.md` | Keep (slightly expanded) | Canonical contributor guide for humans AND AI. |
| `OPERATING.md` | **New** | Single source of truth for future-you + AI: install, daily ops, making changes, repo map, troubleshooting, current state. |
| `CLAUDE.md` | Reduce to ~10-line pointer | Satisfies Claude Code's expected entry point; routes to the real sources. |
| `SETUP.md` | Delete after content migration | Content folds into `OPERATING.md`'s install section. |
| `CONTRIBUTING.md` | Delete after content migration | Content folds into `AGENTS.md`. |

## Detailed Design

### OPERATING.md (new file)

**Length target:** ~300 lines. Dense, scannable, factual.

**Table of contents:**

1. **Who this is for** — one paragraph identifying the two audiences.
2. **Install on a new machine** — both paths (traditional + Nix), decision tree, fresh-laptop checklist. Absorbs `SETUP.md`.
3. **Daily operations** — commands routinely re-run: `make link`, `make doctor`, `make update`, `make verify`, `make daily`, `make bench-shell`, worktree flow.
4. **Making changes** — canonical recipes: add a config, add a package (brew/cargo/npm), add an alias, swap a tool, use local overrides, use machine profiles.
5. **Repo map** — ~1 paragraph per top-level directory, pointing to per-config READMEs for depth. No duplication with those READMEs.
6. **Current state (primary vs backup)** — names which tools are primary (Ghostty, Zellij, Yazi, jj) vs backup/transitional (tmux). Replaces the `NEW` tag system with a time-invariant framing.
7. **Troubleshooting** — common first-run failures: Stow conflicts, Homebrew prefix on Apple Silicon, Nix experimental-features, shell not loading, broken symlinks.

**Content sources:** pulls accurate content from existing `SETUP.md` and useful sections of `CLAUDE.md`. All facts are re-verified against repo state during migration — counts, script names, tool statuses.

### CLAUDE.md (pointer form)

New contents (verbatim):

```markdown
# CLAUDE.md

This file exists because Claude Code reads it. The real content lives elsewhere:

- **Repo conventions, style, testing, commits** → [AGENTS.md](AGENTS.md)
- **How this repo works (install, daily ops, troubleshooting)** → [OPERATING.md](OPERATING.md)
- **Public-facing overview** → [README.md](README.md)

Keep this file minimal. All other top-level docs consolidate into the three above.
```

### AGENTS.md (expanded)

Three changes:

1. **Absorb `CONTRIBUTING.md`.** Its workflow and pull-request checklist fold into `AGENTS.md`'s existing "Commit & Pull Request Guidelines" section.
2. **Add cross-link** to `OPERATING.md` ("For how the repo works, see OPERATING.md").
3. **Add one new short section: "Per-config README convention."** Each `.config/<app>/` should document: why it's here, non-obvious choices, links to upstream docs. Aspirational maintenance standard for the 24 existing READMEs.

### README.md (light edits)

1. **Add callout.** Right after the Quick Start section, add a prominent "**Working on this repo?**" block pointing to `OPERATING.md`.
2. **Strip all `NEW` / `(NEW)` tags** currently present in the README (Features table, Structure diagram, and anywhere else). Includes — but is not limited to — Ghostty, Yazi, Zellij, jj, Nix, broot, navi, ouch. The `NEW` tag system is abandoned entirely; current-state truth lives in `OPERATING.md`'s "primary vs backup" section instead.
3. **Update "Documentation" table** to list `OPERATING.md` and `AGENTS.md`; remove deleted docs (`SETUP.md`, `CONTRIBUTING.md`).
4. **Leave alone:** banner, badges, feature tables, theme table, aliases table, FAQ, troubleshooting, credits. All still useful for GitHub visitors.

### CHANGELOG.md

One new entry under `[Unreleased]`:

```
### Changed
- Consolidated top-level documentation: added OPERATING.md, reduced CLAUDE.md to a pointer, merged CONTRIBUTING.md into AGENTS.md, removed SETUP.md.
```

## Implementation Sequence

1. Draft `OPERATING.md` end-to-end. Verify all facts against repo state (directory counts, script names, tool statuses).
2. Write pointer-form `CLAUDE.md` (replaces existing content).
3. Merge `CONTRIBUTING.md` content into `AGENTS.md`; add cross-link to `OPERATING.md`; add per-config README convention section.
4. Update `README.md` (callout block + strip `NEW` tags + update doc table).
5. Delete `SETUP.md` and `CONTRIBUTING.md`.
6. Update `CHANGELOG.md`.
7. Run `make verify` — catches any broken doc links from deletions.
8. Run `make daily` if available — confirms no shell/test regressions.

## Success Criteria

- A reader matching Audience A or D can identify where to go within 30 seconds of opening the repo.
- `README.md` has a single, unambiguous pointer to `OPERATING.md` near the top.
- No content exists in two top-level docs simultaneously.
- No `NEW` tags remain anywhere in `README.md` or `CLAUDE.md`.
- No references to deleted scripts or stale directory counts.
- `make verify` passes without doc-link errors.
- `CLAUDE.md` is ≤15 lines and contains no standalone facts (only pointers).

## Open Questions

None at time of design approval. All clarifying questions were delegated to the designer and answered inline.
