# 0001: Palette coverage stays an explicit list

Status: accepted (2026-11-14)

## Context

`test/test_palette.bats` checks that every themed file uses only its
palette's colours, through a hand-kept list of `palette path` pairs. An
architecture review proposed replacing the list with discovery: each themed
file would declare its palette in a header comment, and the test would find
files by that header.

## Decision

Keep the explicit list. Several themed files cannot carry a comment at all:
`windows/windows-terminal/danse.json.tpl` is JSON, and others are formats a
tool parses strictly. Discovery would cover only the files that can hold a
header and silently skip the rest, which is worse than a list that is
visibly incomplete when someone forgets to add a line.

## Consequences

A new themed file still needs one line in that list. The rice actually in
use is covered: Field Notebook now has `.config/palette/field-notebook.conf`
and its theme and wallpaper renderer are on the list.
