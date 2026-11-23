#!/usr/bin/env bash
# omarchy/setup.sh - put a Rice and the desktop settings that go with it on an
# Omarchy 4.x machine.
#
# This directory is the Omarchy layer of the checkout, the way windows/ is the
# Windows one. It is not under .config/ because Omarchy owns ~/.config/hypr
# and ~/.config/omarchy: stowing those wholesale would fight `omarchy update`.
# Instead this script places individual files and drives Omarchy's own
# commands. It is idempotent: a second run reports everything as ok.
#
# Dry run by default - it prints what it would do and changes nothing.
#
# Usage:
#   omarchy/setup.sh                        # dry run, every step
#   omarchy/setup.sh --apply                # do it
#   omarchy/setup.sh --only hypr            # one step (names below)
#   omarchy/setup.sh --rice monochrome-43   # another rice, for this run
#
# Which rice: the Rice module (.config/palette/rice.sh) reads the one-word
# ~/.config/palette/rice.local and falls back to Omarchy's default,
# field-notebook. --rice or $OMARCHY_RICE overrides it for one run.
#
# A rice is a directory, rices/<rice>/, and every step acts on whatever that
# directory ships; no step names a rice. Everything is optional except theme/
# and hypr.lua:
#   theme/            colors.toml, icons.theme
#   backgrounds       executable: `backgrounds --check DIR` / `backgrounds DIR`
#   hypr.lua          the look, require()d from looknfeel.lua
#   hypr/             more files for ~/.config/hypr (e.g. hyprsunset.conf)
#   packages.pacman   official-repo packages (bin/manifest list rice-pacman)
#   packages.aur      AUR packages (bin/manifest list rice-aur)
#   hooks/<event>.d/  Omarchy hooks
#   bin/  share/      ~/.local/bin and ~/.local/share/<rice>
#   branding/         ~/.config/omarchy/branding
#
# Steps, in order:
#   packages  the rice's packages pacman does not have yet, via
#             `omarchy pkg add` / `omarchy pkg aur add`.
#   extras    rice bin/, share/ and branding/ linked into place.
#   hooks     hooks/<event>.d/ here (every rice) and the rice's own, linked
#             into ~/.config/omarchy/hooks/<event>.d/. Before the theme step,
#             because `omarchy theme set` fires theme-set hooks.
#   theme     theme/ linked into ~/.config/omarchy/themes/<rice>, backgrounds
#             populated by the rice's script when its --check fails, then
#             `omarchy theme set <rice>` if it is not already current.
#   plugins   each plugin in plugins.tsv: `omarchy plugin add`, then checked
#             out at its pinned commit and validated; then enabled if marked
#             yes, disabled if marked no. `external` plugins are managed
#             outside this repo and only reported on.
#   bar       `omarchy bar position`, and bar.json's layout written to
#             .bar.layout in ~/.config/omarchy/shell.json (only that key
#             changes; backed up first).
#   idle      idle.json written to .idle in the same shell.json, the same
#             way: screensaver and auto-lock timeouts in seconds (0 off).
#   hypr      hypr.lua linked as ~/.config/hypr/<rice_with_underscores>.lua
#             and require()d once from looknfeel.lua (another rice's require
#             is taken out), plus the rice's hypr/ files.
#   ghostty   one line in ~/.config/ghostty/config.local (gitignored) that
#             includes ghostty.conf from here: zsh as the terminal's command
#             and the Omarchy-only Ghostty settings. Skipped while zsh is
#             missing, since Ghostty could not start a shell at all.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$HERE/.." && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
OMARCHY_CONFIG="$CONFIG_DIR/omarchy"
HYPR_DIR="$CONFIG_DIR/hypr"
OMARCHY_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/current"
export PLATFORM_OMARCHY_SYSTEM_DIR="${PLATFORM_OMARCHY_SYSTEM_DIR:-/usr/share/omarchy}"
readonly RICES_DIR="$HERE/rices"

# Overridable for tests only.
PLUGINS_TSV="${OMARCHY_PLUGINS_TSV:-$HERE/plugins.tsv}"
BIN_DIR="${OMARCHY_BIN_DIR:-$HOME/.local/bin}"
SHARE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
# ghostty.conf itself names /usr/bin/zsh.
GHOSTTY_ZSH="${OMARCHY_GHOSTTY_ZSH:-/usr/bin/zsh}"
readonly GHOSTTY_INCLUDE="config-file = $HERE/ghostty.conf"

readonly STEPS="packages|extras|hooks|theme|plugins|bar|idle|hypr|ghostty"

PLAN_NAME="setup.sh"
# shellcheck source=../bin/lib/plan.sh
source "$DOTFILES_DIR/bin/lib/plan.sh"
# shellcheck source=../.config/palette/rice.sh
source "$DOTFILES_DIR/.config/palette/rice.sh"

ONLY=""
RICE_ARG="${OMARCHY_RICE:-}"

usage() { sed -n '2,/^[^#]/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --apply) APPLY=1 ;;
        --only)
            ONLY="${2:-}"
            [[ "$ONLY" =~ ^($STEPS)$ ]] || {
                echo "setup.sh: --only takes $STEPS" >&2
                exit 2
            }
            shift
            ;;
        --rice)
            RICE_ARG="${2:-}"
            [[ -n "$RICE_ARG" ]] || { echo "setup.sh: --rice takes a rice name" >&2; exit 2; }
            shift
            ;;
        -h | --help) usage; exit 0 ;;
        *) echo "setup.sh: unknown argument: $1" >&2; exit 2 ;;
    esac
    shift
done

if [[ -n "$RICE_ARG" ]]; then
    RICE="$RICE_ARG"
else
    rice_select omarchy
fi
if ! rice_available "$RICE" omarchy || [[ ! -d "$RICES_DIR/$RICE" ]]; then
    echo "setup.sh: unknown rice '$RICE' (one of: $(rice_list omarchy | tr '\n' ' '))" >&2
    exit 2
fi
readonly RICE
readonly RICE_DIR="$RICES_DIR/$RICE"
readonly HYPR_MODULE="${RICE//-/_}"
readonly HYPR_REQUIRE="require(\"hypr.$HYPR_MODULE\")"

wants() { [[ -z "$ONLY" || "$ONLY" == "$1" ]]; }

# Link every file directly under <src> to the same name under <dest>.
link_dir_files() {
    local src="$1" dest="$2" f
    [[ -d "$src" ]] || return 0
    for f in "$src"/*; do
        [[ -f "$f" ]] && plan_link "$f" "$dest/$(basename "$f")"
    done
    return 0
}

step_packages() {
    echo "packages: $RICE_DIR/packages.{pacman,aur}"
    local kind name missing
    for kind in pacman aur; do
        missing=()
        while read -r name; do
            [[ -n "$name" ]] || continue
            if pacman -Q "$name" > /dev/null 2>&1; then
                ok "$name"
            else
                missing+=("$name")
            fi
        done < <("$DOTFILES_DIR/bin/manifest" list "rice-$kind" "$RICE")
        ((${#missing[@]})) || continue
        if [[ "$kind" == pacman ]]; then
            change "omarchy pkg add ${missing[*]}" && omarchy pkg add "${missing[@]}"
        else
            change "omarchy pkg aur add ${missing[*]}" && omarchy pkg aur add "${missing[@]}"
        fi
    done
    return 0
}

step_extras() {
    echo "extras: $RICE_DIR/{bin,share,branding}"
    link_dir_files "$RICE_DIR/bin" "$BIN_DIR"
    link_dir_files "$RICE_DIR/share" "$SHARE_DIR/$RICE"
    link_dir_files "$RICE_DIR/branding" "$OMARCHY_CONFIG/branding"
}

# Link every file under <root>/<event>.d/ into Omarchy's hook directories.
link_hooks() {
    local root="$1" d
    for d in "$root"/*.d; do
        [[ -d "$d" ]] && link_dir_files "$d" "$OMARCHY_CONFIG/hooks/$(basename "$d")"
    done
    return 0
}

step_hooks() {
    echo "hooks: $HERE/hooks, $RICE_DIR/hooks"
    link_hooks "$HERE/hooks"
    link_hooks "$RICE_DIR/hooks"
}

step_theme() {
    echo "theme: $RICE"
    local dir="$OMARCHY_CONFIG/themes/$RICE"
    link_dir_files "$RICE_DIR/theme" "$dir"

    local script="$RICE_DIR/backgrounds"
    if [[ ! -x "$script" ]]; then
        :
    elif "$script" --check "$dir/backgrounds"; then
        ok "$dir/backgrounds"
    elif change "populate $dir/backgrounds ($RICE/backgrounds)"; then
        "$script" "$dir/backgrounds" || warn "$RICE/backgrounds failed; re-run once it can"
    fi

    local current=""
    [[ -r "$OMARCHY_STATE/theme.name" ]] && current="$(cat "$OMARCHY_STATE/theme.name")"
    if [[ "$current" == "$RICE" ]]; then
        ok "current theme is $RICE"
    elif change "omarchy theme set $RICE (current: ${current:-unknown})"; then
        omarchy theme set "$RICE"
    fi
}

plugin_enabled() {
    grep -Fxq "$1" <<< "$ENABLED"
}

step_plugins() {
    echo "plugins: $PLUGINS_TSV"
    local plugins_dir="$OMARCHY_CONFIG/plugins"
    ENABLED="$(omarchy plugin list --json 2> /dev/null |
        jq -r '.[] | select(.enabled) | .id' 2> /dev/null || true)"

    local id src commit enable dir head
    while read -r id src commit enable; do
        [[ -z "$id" || "$id" == \#* ]] && continue
        dir="$plugins_dir/$id"

        if [[ "$src" == external ]]; then
            # Owned elsewhere (bar.json places it); report, never touch.
            if [[ -e "$dir" ]]; then
                ok "$id (external, not managed here)"
            else
                note "$id is external and not installed here"
            fi
            continue
        else
            [[ "$commit" =~ ^[0-9a-f]{40}$ ]] || die "plugins.tsv: $id: bad commit $commit"
            if [[ ! -d "$dir" ]]; then
                if change "omarchy plugin add $src, then pin $id at ${commit:0:12}"; then
                    omarchy plugin add "$src" --yes
                    [[ -d "$dir/.git" ]] || die "$src did not install as $id"
                fi
            fi
            if [[ -d "$dir/.git" ]]; then
                head="$(git -C "$dir" rev-parse HEAD)"
                if [[ "$head" == "$commit" ]]; then
                    ok "$id @ ${commit:0:12}"
                elif [[ -n "$(git -C "$dir" status --porcelain)" ]]; then
                    warn "$id has local changes; not moving it to ${commit:0:12}"
                elif change "check out $id at ${commit:0:12} (was ${head:0:12})"; then
                    git -C "$dir" cat-file -e "$commit^{commit}" 2> /dev/null ||
                        git -C "$dir" fetch --quiet origin
                    git -C "$dir" -c advice.detachedHead=false checkout --quiet "$commit"
                    omarchy plugin validate "$dir"
                fi
            elif [[ -e "$dir" ]]; then
                warn "$dir exists but is not a git checkout; left alone"
            fi
        fi

        if [[ "$enable" == yes ]]; then
            if plugin_enabled "$id"; then
                ok "$id enabled"
            elif change "omarchy plugin enable $id"; then
                omarchy plugin enable "$id"
            fi
        elif plugin_enabled "$id" && change "omarchy plugin disable $id (marked no)"; then
            omarchy plugin disable "$id"
        fi
    done < "$PLUGINS_TSV"
}

# Write one JSON file from here into one key path of shell.json: only that
# key changes (other keys keep their values and order), after a backup.
shell_json_set() {
    local key="$1" src="$2" shell_json="$OMARCHY_CONFIG/shell.json" tmp
    mkdir -p "$OMARCHY_CONFIG"
    [[ -s "$shell_json" ]] || echo '{"version": 1}' > "$shell_json"
    cp -p "$shell_json" "$(plan_backup "$shell_json")"
    tmp="$(mktemp "$shell_json.XXXXXX")"
    jq --arg k "$key" --slurpfile v "$src" 'setpath($k | split("."); $v[0])' "$shell_json" > "$tmp"
    mv "$tmp" "$shell_json"
    omarchy-shell shell reloadConfig > /dev/null 2>&1 || true
}

step_bar() {
    echo "bar: $HERE/bar.json"
    local shell_json="$OMARCHY_CONFIG/shell.json"
    local want_pos have_pos="" want have=""
    want_pos="$(jq -r '.position' "$HERE/bar.json")"
    want="$(jq -S -c '.layout' "$HERE/bar.json")"
    if [[ -s "$shell_json" ]]; then
        have_pos="$(jq -r '.bar.position // ""' "$shell_json")"
        have="$(jq -S -c '.bar.layout // {}' "$shell_json")"
    fi

    if [[ "$have_pos" == "$want_pos" ]]; then
        ok "bar position $want_pos"
    elif change "omarchy bar position $want_pos (was ${have_pos:-default})"; then
        omarchy bar position "$want_pos"
    fi

    if [[ "$have" == "$want" ]]; then
        ok "bar layout"
    elif change "set .bar.layout in $shell_json from bar.json (backup: shell.json.dotfiles-bak.<epoch>)"; then
        local tmp
        tmp="$(mktemp)"
        jq .layout "$HERE/bar.json" > "$tmp"
        shell_json_set bar.layout "$tmp"
        rm -f "$tmp"
    fi
}

step_idle() {
    echo "idle: $HERE/idle.json"
    local shell_json="$OMARCHY_CONFIG/shell.json" want have=""
    want="$(jq -S -c . "$HERE/idle.json")"
    [[ -s "$shell_json" ]] && have="$(jq -S -c '.idle // {}' "$shell_json")"
    if [[ "$have" == "$want" ]]; then
        ok "idle $want"
    elif change "set .idle in $shell_json to $want (was ${have:-unset})"; then
        shell_json_set idle "$HERE/idle.json"
    fi
}

# A rice's hypr.lua may carry an inline marker: the first hl.curve name it
# defines. Finding it in looknfeel.lua means a pasted copy of the rice.
inline_mark() {
    sed -nE 's/^hl\.curve\("([^"]+)".*/hl.curve("\1"/p' "$1" | head -n1
}

step_hypr() {
    echo "hypr: $HYPR_MODULE"
    plan_link "$RICE_DIR/hypr.lua" "$HYPR_DIR/$HYPR_MODULE.lua"
    link_dir_files "$RICE_DIR/hypr" "$HYPR_DIR"

    local looknfeel="$HYPR_DIR/looknfeel.lua" other module line mark tmp
    # Only one rice's look loads: a require for another rice is taken out,
    # with the marker comment this script wrote above it. awk, not sed -i:
    # BSD sed has no suffix-less -i, and the tests run on macOS too.
    while read -r other; do
        [[ "$other" == "$RICE" ]] && continue
        module="${other//-/_}"
        line="require(\"hypr.$module\")"
        if [[ -f "$looknfeel" ]] && grep -Fxq "$line" "$looknfeel" &&
            change "remove $line from $looknfeel (switching to $RICE)"; then
            tmp="$(mktemp "$looknfeel.XXXXXX")"
            awk -v req="$line" '
                held != "" { if ($0 == req) { held = ""; next } print held; held = "" }
                /^-- .* rice, from the dotfiles checkout/ { held = $0; next }
                $0 == req { next }
                { print }
                END { if (held != "") print held }
            ' "$looknfeel" > "$tmp"
            cat "$tmp" > "$looknfeel"
            rm -f "$tmp"
        fi
    done < <(rice_list omarchy)

    mark="$(inline_mark "$RICE_DIR/hypr.lua")"
    if [[ -f "$looknfeel" ]] && grep -Fq "$HYPR_REQUIRE" "$looknfeel"; then
        ok "$looknfeel loads hypr.$HYPR_MODULE"
    elif [[ -n "$mark" && -f "$looknfeel" ]] && grep -Fq "$mark" "$looknfeel"; then
        # A hand-pasted copy of the rice. Appending the require as well
        # would apply it twice; leave the user to choose which to keep.
        warn "$looknfeel already holds an inline copy of the rice ($mark)."
        warn "Delete that block, then re-run to load it from the dotfiles instead."
    elif change "append $HYPR_REQUIRE to $looknfeel"; then
        mkdir -p "$HYPR_DIR"
        printf '\n-- %s rice, from the dotfiles checkout (omarchy/setup.sh)\n%s\n' \
            "$RICE" "$HYPR_REQUIRE" >> "$looknfeel"
    fi
}

step_ghostty() {
    echo "ghostty: $HERE/ghostty.conf"
    local local_conf="$CONFIG_DIR/ghostty/config.local"
    if [[ -f "$local_conf" ]] && grep -Fxq "$GHOSTTY_INCLUDE" "$local_conf"; then
        ok "$local_conf includes ghostty.conf"
    elif [[ ! -x "$GHOSTTY_ZSH" ]]; then
        warn "$GHOSTTY_ZSH not found; install zsh (make arch) before pointing Ghostty at it"
        return 0
    elif change "append '$GHOSTTY_INCLUDE' to $local_conf"; then
        mkdir -p "$(dirname "$local_conf")"
        printf '# Omarchy-only Ghostty settings, from the dotfiles (omarchy/setup.sh)\n%s\n' \
            "$GHOSTTY_INCLUDE" >> "$local_conf"
    fi
    # Omarchy's own config never reads config.local, so give it the one include line
    # the dotfiles config already has (a relative config-file resolves next to it).
    local main_conf="$CONFIG_DIR/ghostty/config"
    if [[ -f "$main_conf" ]] && ! grep -Fq 'config-file = ?"config.local"' "$main_conf" &&
        change "append 'config-file = ?\"config.local\"' to $main_conf"; then
        printf '\n# dotfiles: read config.local (omarchy/setup.sh)\nconfig-file = ?"config.local"\n' >> "$main_conf"
    fi
}

main() {
    if ! "$DOTFILES_DIR/bin/platform" is-omarchy; then
        ((APPLY)) && die "not an Omarchy machine (bin/platform is-omarchy); nothing applied"
        echo "Not an Omarchy machine (bin/platform is-omarchy): nothing to do."
        return 0
    fi
    local tool
    for tool in omarchy jq git; do
        command -v "$tool" > /dev/null 2>&1 || die "$tool not found on PATH"
    done

    ((APPLY)) || echo "Dry run: nothing will change. Re-run with --apply to act."
    echo "rice: $RICE"
    wants packages && step_packages
    wants extras && step_extras
    wants hooks && step_hooks
    wants theme && step_theme
    wants plugins && step_plugins
    wants bar && step_bar
    wants idle && step_idle
    wants hypr && step_hypr
    wants ghostty && step_ghostty
    plan_summary
}

main
