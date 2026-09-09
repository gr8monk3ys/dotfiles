#!/usr/bin/env bash
# The layout of a dotfiles-backup snapshot, described once.
#
# dotfiles-backup writes a snapshot; dotfiles-restore reads one. Before this
# file existed each knew the layout separately, and they had drifted: backup
# wrote nine artifacts and restore handled two, so seven were produced and
# read by nothing.
#
# A snapshot is a *forensic record*, not a replayable installer. Replay lives
# in install/ and `make` — see CONTEXT.md § Snapshot. What a snapshot uniquely
# holds is drift: what was actually on the machine at that moment, including
# things no manifest tracks.
#
# Usage:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$SCRIPT_DIR/lib/snapshot.sh"
#
#   snapshot_rows                      # every row, name|class|description|legacy
#   snapshot_names                     # artifact names only
#   snapshot_class <name>              # tree | record | metadata | "" if unknown
#   snapshot_description <name>
#   snapshot_present <dir> <name>      # echoes the path present in <dir>,
#                                      # falling back to the legacy name; 1 if absent
#   snapshot_provenance <file> <cmd>   # prepend a "# produced by" header
#
# Classes:
#   tree      a directory of files; dotfiles-restore replays it
#   record    a text record of installed state; preserved, never replayed
#   metadata  describes the snapshot itself

# Guard against double-sourcing (the readonly table would error).
[[ -n "${DOTFILES_SNAPSHOT_LOADED:-}" ]] && return 0
readonly DOTFILES_SNAPSHOT_LOADED=1

# name|class|description|legacy-name (legacy optional).
#
# Deliberately a row-per-line string rather than an associative array: macOS
# still ships bash 3.2, no other lib here uses bash-4 features, and the drift
# test greps this table without sourcing the file.
readonly SNAPSHOT_ARTIFACTS='configs|tree|Non-symlinked user configs from the home directory
ssh|tree|SSH config and known_hosts (never private keys)
Brewfile|record|Homebrew formulae
Caskfile|record|Homebrew casks
npm-global-list.txt|record|Global npm packages|npmfile.txt
cargo-installed.txt|record|Cargo-installed crates|Rustfile.txt
vscode-extensions.txt|record|VS Code extension ids
vscodium-extensions.txt|record|VSCodium extension ids
MANIFEST.txt|metadata|Human-readable summary of this snapshot'

snapshot_rows() {
    printf '%s\n' "$SNAPSHOT_ARTIFACTS"
}

snapshot_names() {
    local name rest
    while IFS='|' read -r name rest; do
        if [[ -n "$name" ]]; then echo "$name"; fi
    done <<< "$SNAPSHOT_ARTIFACTS"
    # Explicit: without it the last loop iteration's test sets the exit status,
    # so a listing whose final row does not match would report failure.
    return 0
}

snapshot_names_of_class() {
    local want="$1" name class rest
    while IFS='|' read -r name class rest; do
        if [[ "$class" == "$want" ]]; then echo "$name"; fi
    done <<< "$SNAPSHOT_ARTIFACTS"
    # Explicit: without it the last loop iteration's test sets the exit status,
    # so `snapshot_names_of_class tree` failed purely because the final row
    # (MANIFEST.txt) is metadata.
    return 0
}

snapshot_class() {
    local want="$1" name class desc legacy
    while IFS='|' read -r name class desc legacy; do
        if [[ "$name" == "$want" || ( -n "$legacy" && "$legacy" == "$want" ) ]]; then
            echo "$class"
            return 0
        fi
    done <<< "$SNAPSHOT_ARTIFACTS"
    return 1
}

snapshot_description() {
    local want="$1" name class desc legacy
    while IFS='|' read -r name class desc legacy; do
        if [[ "$name" == "$want" || ( -n "$legacy" && "$legacy" == "$want" ) ]]; then
            echo "$desc"
            return 0
        fi
    done <<< "$SNAPSHOT_ARTIFACTS"
    return 1
}

# Echo the path for <name> inside <dir>, falling back to the legacy filename
# so a snapshot taken before a rename still resolves. Returns 1 if neither
# is present.
snapshot_present() {
    local dir="$1" want="$2" name class desc legacy
    while IFS='|' read -r name class desc legacy; do
        [[ "$name" == "$want" ]] || continue
        if [[ -e "$dir/$name" ]]; then
            echo "$dir/$name"
            return 0
        fi
        if [[ -n "$legacy" && -e "$dir/$legacy" ]]; then
            echo "$dir/$legacy"
            return 0
        fi
        return 1
    done <<< "$SNAPSHOT_ARTIFACTS"
    return 1
}

# Prepend a provenance header so a record can never be mistaken for a
# manifest, whatever it is named or wherever it is copied to.
snapshot_provenance() {
    local file="$1" produced_by="$2" tmp
    [[ -f "$file" ]] || return 0
    tmp="$(mktemp)"
    {
        echo "# dotfiles snapshot record - not an install manifest."
        echo "# produced by: $produced_by"
        echo "# produced at: $(date)"
        echo ""
        cat "$file"
    } > "$tmp"
    mv "$tmp" "$file"
}
