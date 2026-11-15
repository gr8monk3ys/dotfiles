# 0002: bin/palette keeps danse as its default

Status: accepted (2026-11-14)

## Context

The Rice module (`.config/palette/rice.sh`) defaults to `monochrome-43` on
macOS and `field-notebook` on Omarchy, while `bin/palette` with no
`PALETTE=` reads `danse`. An architecture review flagged this as a leaked
default: `palette get fg` does not describe the active rice.

## Decision

Leave `bin/palette`'s default alone. Its unqualified callers are the CLI
tools (bat, eza, zellij, yazi, delta, the zsh highlight styles), which the
repo deliberately keeps on danse whatever the desktop rice is. Defaulting it
to the rice would re-theme every CLI tool when a machine switches rice.

## Consequences

A caller that wants the rice's colours asks for them by name:
`PALETTE="$RICE" palette ...` after `rice_select`. CONTEXT.md's **Rice** entry
says the two are different things.
