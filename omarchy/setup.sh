#!/usr/bin/env bash
# omarchy/setup.sh - install an Omarchy rice (Field Notebook or Monochrome 43)
# and the desktop settings that go with it, on an Omarchy 4.x machine.
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
#   omarchy/setup.sh                     # dry run, every step
#   omarchy/setup.sh --apply             # do it
#   omarchy/setup.sh --only hypr         # one step (names below)
#   omarchy/setup.sh --rice monochrome-43   # another rice than omarchy/rice
#
# The rice is read from omarchy/rice (one word: field-notebook or
# monochrome-43); --rice or $OMARCHY_RICE overrides it for one run.
#
# Steps, in order:
#   packages (field-notebook) each package in field-notebook/packages.tsv
#            that pacman does not have: `omarchy pkg add` for repo ones,
#            `omarchy pkg aur add` for AUR ones.
#   hooks    each file under hooks/<event>.d/ here (and, for field-notebook,
#            field-notebook/hooks/<event>.d/) linked into
#            ~/.config/omarchy/hooks/<event>.d/.
#   extras   (field-notebook) the session scripts in field-notebook/bin
#            linked into ~/.local/bin, field-notebook/share into
#            ~/.local/share/field-notebook, and the screensaver art into
#            ~/.config/omarchy/branding/screensaver.txt.
#   theme    ~/.config/omarchy/themes/<rice>: colors.toml and icons.theme
#            linked from themes/<rice>/ here. Backgrounds are not tracked:
#            monochrome-43 copies Omarchy's Vantablack ones plus 43PR's
#            wallpaper, fetched by URL and checked against a SHA-256;
#            field-notebook renders its plates with
#            field-notebook/share/make-wallpapers.sh when none are there.
#            Then `omarchy theme set <rice>` if it is not already current.
#   plugins  each plugin in plugins.tsv: `omarchy plugin add`, then checked
#            out at its pinned commit and validated; then enabled if marked
#            yes, disabled if marked no. `external` plugins are managed outside this repo: their
#            directory is never created, linked, moved or enabled from here.
#   bar      `omarchy bar position`, and bar.json's layout written to
#            .bar.layout in ~/.config/omarchy/shell.json (other keys and
#            their order untouched; backed up first to
#            shell.json.dotfiles-bak.<epoch>).
#   idle     idle.json written to .idle in the same shell.json, the same
#            way: the screensaver and auto-lock timeouts, in seconds (0 off).
#   hypr     hypr/<rice>.lua linked into ~/.config/hypr and a require() for
#            it appended once to ~/.config/hypr/looknfeel.lua; for
#            field-notebook also hypr/hyprsunset.conf (night-light schedule).
#   ghostty  one line in ~/.config/ghostty/config.local (gitignored) that
#            includes ghostty.conf from here: zsh as the terminal's command
#            and the Omarchy-only Ghostty settings. Skipped while zsh is
#            missing, since Ghostty could not start a shell at all.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$HERE/.." && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
OMARCHY_CONFIG="$CONFIG_DIR/omarchy"
HYPR_DIR="$CONFIG_DIR/hypr"
OMARCHY_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/current"
OMARCHY_SYSTEM_DIR="${PLATFORM_OMARCHY_SYSTEM_DIR:-/usr/share/omarchy}"

# Overridable for tests only.
PLUGINS_TSV="${OMARCHY_PLUGINS_TSV:-$HERE/plugins.tsv}"

# Overridable for tests only.
BIN_DIR="${OMARCHY_BIN_DIR:-$HOME/.local/bin}"
SHARE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
# 43PR/dotfiles ships this wallpaper at its repo root. Pinned to a commit and
# a hash so the bytes cannot change under us; it is not committed here.
readonly WALLPAPER_URL="https://raw.githubusercontent.com/43PR/dotfiles/b015f39d558cdd4c77907132532d56be8ab34594/wallhaven-k8jvm7.jpg"
readonly WALLPAPER_SHA256="acffe6dc9dd07a5d0e2d7539a7725430239be418a3817b4c58be2b5af7ab2759"
readonly WALLPAPER_NAME="00-43pr-wallhaven.jpg"
readonly GHOSTTY_INCLUDE="config-file = $HERE/ghostty.conf"
# Overridable for tests only; ghostty.conf itself names /usr/bin/zsh.
GHOSTTY_ZSH="${OMARCHY_GHOSTTY_ZSH:-/usr/bin/zsh}"

readonly STEPS="packages|theme|plugins|bar|idle|hypr|hooks|extras|ghostty"

APPLY=0
ONLY=""
CHANGES=0
RICE="${OMARCHY_RICE:-}"

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
            RICE="${2:-}"
            [[ -n "$RICE" ]] || { echo "setup.sh: --rice takes a rice name" >&2; exit 2; }
            shift
            ;;
        -h | --help) usage; exit 0 ;;
        *) echo "setup.sh: unknown argument: $1" >&2; exit 2 ;;
    esac
    shift
done

[[ -n "$RICE" ]] || RICE="$(tr -d '[:space:]' < "$HERE/rice" 2> /dev/null || true)"
case "$RICE" in
    field-notebook) HYPR_MODULE="field_notebook" INLINE_MARK='hl.curve("notebook"' ;;
    monochrome-43) HYPR_MODULE="monochrome_43" INLINE_MARK='hl.curve("riceOut"' ;;
    *) echo "setup.sh: unknown rice '${RICE}' (field-notebook | monochrome-43)" >&2; exit 2 ;;
esac
readonly RICE HYPR_MODULE INLINE_MARK
readonly THEME="$RICE"
readonly HYPR_REQUIRE="require(\"hypr.$HYPR_MODULE\")"
readonly FN_DIR="$HERE/field-notebook"

ok() { printf '  ok      %s\n' "$*"; }
note() { printf '  note    %s\n' "$*"; }
warn() { printf '  WARN    %s\n' "$*" >&2; }
die() { printf 'setup.sh: %s\n' "$*" >&2; exit 1; }

# Announce a change and say whether to make it: true under --apply.
change() {
    CHANGES=$((CHANGES + 1))
    if ((APPLY)); then
        printf '  do      %s\n' "$*"
        return 0
    fi
    printf '  would   %s\n' "$*"
    return 1
}

wants() { [[ -z "$ONLY" || "$ONLY" == "$1" ]]; }

# Point dest at src with a symlink. Something else already there is moved to
# dest.dotfiles-bak - unless it is an identical copy, which is simply replaced.
link() {
    local src="$1" dest="$2" backup="$2.dotfiles-bak"
    if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
        ok "$dest"
        return 0
    fi
    if [[ ! -L "$dest" ]] && { { [[ -f "$dest" ]] && cmp -s "$src" "$dest"; } ||
        { [[ -d "$dest" ]] && diff -rq "$src" "$dest" > /dev/null 2>&1; }; }; then
        change "replace identical copy $dest with a link" || return 0
        rm -rf "$dest"
    elif [[ -e "$dest" || -L "$dest" ]]; then
        [[ -e "$backup" || -L "$backup" ]] && die "$dest differs and $backup already exists; resolve by hand"
        change "move $dest -> $backup, then link it" || return 0
        mkdir -p "$(dirname "$backup")"
        mv "$dest" "$backup"
    else
        change "link $dest -> $src" || return 0
    fi
    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
}

backgrounds_monochrome_43() {
    local bg="$1" vanta="" f
    vanta="$(omarchy theme dir vantablack 2> /dev/null || true)"
    [[ -d "$vanta" ]] || vanta="$OMARCHY_SYSTEM_DIR/themes/vantablack"
    if [[ -d "$vanta/backgrounds" ]]; then
        for f in "$vanta"/backgrounds/*; do
            [[ -f "$f" ]] || continue
            if [[ -f "$bg/$(basename "$f")" ]]; then
                ok "$bg/$(basename "$f")"
            elif change "copy $(basename "$f") from $vanta/backgrounds"; then
                mkdir -p "$bg"
                cp "$f" "$bg/"
            fi
        done
    else
        warn "no Vantablack backgrounds found under $vanta; skipped"
    fi

    local wp="$bg/$WALLPAPER_NAME"
    if [[ -f "$wp" ]] && sha256sum "$wp" | grep -q "^$WALLPAPER_SHA256 "; then
        ok "$wp"
    elif change "fetch 43PR wallpaper -> $wp (sha256-checked)"; then
        mkdir -p "$bg"
        curl -fsSL --max-time 120 -o "$wp.part" "$WALLPAPER_URL" ||
            { rm -f "$wp.part"; die "could not fetch $WALLPAPER_URL"; }
        sha256sum "$wp.part" | grep -q "^$WALLPAPER_SHA256 " ||
            { rm -f "$wp.part"; die "wallpaper hash mismatch; refusing it"; }
        mv "$wp.part" "$wp"
    fi
}

# The plates are rendered, not tracked: three 2560x1440 PNGs are ~35 MB.
backgrounds_field_notebook() {
    local bg="$1"
    if compgen -G "$bg/*.png" > /dev/null || compgen -G "$bg/*.jpg" > /dev/null; then
        ok "$bg has backgrounds"
    elif ! command -v magick > /dev/null 2>&1; then
        warn "imagemagick missing; run the packages step, then re-run to render the plates"
    elif change "render Field Notebook plates into $bg (make-wallpapers.sh)"; then
        "$FN_DIR/share/make-wallpapers.sh" "$bg"
    fi
}

step_theme() {
    echo "theme: $THEME"
    local dir="$OMARCHY_CONFIG/themes/$THEME" f
    for f in colors.toml icons.theme; do
        link "$HERE/themes/$THEME/$f" "$dir/$f"
    done

    "backgrounds_${RICE//-/_}" "$dir/backgrounds"

    local current=""
    [[ -r "$OMARCHY_STATE/theme.name" ]] && current="$(cat "$OMARCHY_STATE/theme.name")"
    if [[ "$current" == "$THEME" ]]; then
        ok "current theme is $THEME"
    elif change "omarchy theme set $THEME (current: ${current:-unknown})"; then
        omarchy theme set "$THEME"
    fi
}

plugin_enabled() {
    printf '%s\n' "$ENABLED" | grep -Fxq "$1"
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

step_hypr() {
    echo "hypr: $HYPR_MODULE"
    link "$HERE/hypr/$HYPR_MODULE.lua" "$HYPR_DIR/$HYPR_MODULE.lua"
    [[ "$RICE" == field-notebook ]] && link "$HERE/hypr/hyprsunset.conf" "$HYPR_DIR/hyprsunset.conf"

    local looknfeel="$HYPR_DIR/looknfeel.lua" other line
    # Only one rice's look loads: a require for another rice is taken out.
    for other in field_notebook monochrome_43; do
        [[ "$other" == "$HYPR_MODULE" ]] && continue
        line="require(\"hypr.$other\")"
        if [[ -f "$looknfeel" ]] && grep -Fxq "$line" "$looknfeel" &&
            change "remove $line from $looknfeel (switching to $RICE)"; then
            sed -i "/^-- .* rice, from the dotfiles checkout/{N;/hypr\.$other/d}; /^require(\"hypr\.$other\")\$/d" "$looknfeel"
        fi
    done
    if [[ -f "$looknfeel" ]] && grep -Fq "$HYPR_REQUIRE" "$looknfeel"; then
        ok "$looknfeel loads hypr.$HYPR_MODULE"
    elif [[ -f "$looknfeel" ]] && grep -Fq "$INLINE_MARK" "$looknfeel"; then
        # A hand-pasted copy of the snippet. Appending the require as well
        # would apply it twice; leave the user to choose which to keep.
        warn "$looknfeel already holds an inline copy of the rice ($INLINE_MARK)."
        warn "Delete that block, then re-run to load it from the dotfiles instead."
    elif change "append $HYPR_REQUIRE to $looknfeel"; then
        mkdir -p "$HYPR_DIR"
        printf '\n-- %s rice, from the dotfiles checkout (omarchy/setup.sh)\n%s\n' \
            "$RICE" "$HYPR_REQUIRE" >> "$looknfeel"
    fi
}

# Write one JSON file from here into one top-level key of shell.json: only
# that key changes (other keys keep their values and order), after a backup.
shell_json_set() {
    local key="$1" src="$2" shell_json="$OMARCHY_CONFIG/shell.json" tmp backup
    mkdir -p "$OMARCHY_CONFIG"
    [[ -s "$shell_json" ]] || echo '{"version": 1}' > "$shell_json"
    # Two steps can back up within one second; never reuse a name.
    local n=0
    backup="$shell_json.dotfiles-bak.$(date +%s)"
    while [[ -e "$backup" ]]; do n=$((n + 1)); backup="$shell_json.dotfiles-bak.$(date +%s).$n"; done
    cp -p "$shell_json" "$backup"
    tmp="$(mktemp "$shell_json.XXXXXX")"
    jq --arg k "$key" --slurpfile v "$src" 'setpath($k | split("."); $v[0])' "$shell_json" > "$tmp"
    mv "$tmp" "$shell_json"
    omarchy-shell shell reloadConfig > /dev/null 2>&1 || true
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

# Link every file under <root>/<event>.d/ into Omarchy's hook directories.
link_hooks() {
    local root="$1" f event
    [[ -d "$root" ]] || return 0
    for f in "$root"/*.d/*; do
        [[ -f "$f" ]] || continue
        event="$(basename "$(dirname "$f")")"
        link "$f" "$OMARCHY_CONFIG/hooks/$event/$(basename "$f")"
    done
}

step_hooks() {
    echo "hooks: $HERE/hooks"
    link_hooks "$HERE/hooks"
    [[ "$RICE" == field-notebook ]] && link_hooks "$FN_DIR/hooks"
    return 0
}

step_extras() {
    echo "extras: $FN_DIR"
    if [[ "$RICE" != field-notebook ]]; then
        ok "nothing for $RICE"
        return 0
    fi
    local f
    for f in "$FN_DIR"/bin/*; do
        link "$f" "$BIN_DIR/$(basename "$f")"
    done
    for f in "$FN_DIR"/share/*; do
        link "$f" "$SHARE_DIR/field-notebook/$(basename "$f")"
    done
    link "$FN_DIR/branding/screensaver.txt" "$OMARCHY_CONFIG/branding/screensaver.txt"
}

step_packages() {
    echo "packages: $FN_DIR/packages.tsv"
    if [[ "$RICE" != field-notebook ]]; then
        ok "nothing for $RICE"
        return 0
    fi
    local name src _ repo=() aur=()
    while read -r name src _; do
        [[ -z "$name" || "$name" == \#* ]] && continue
        if pacman -Q "$name" > /dev/null 2>&1; then
            ok "$name"
            continue
        fi
        case "$src" in
            repo) repo+=("$name") ;;
            aur) aur+=("$name") ;;
            *) die "packages.tsv: $name: source must be repo|aur, not $src" ;;
        esac
    done < "$FN_DIR/packages.tsv"
    if ((${#repo[@]})) && change "omarchy pkg add ${repo[*]}"; then
        omarchy pkg add "${repo[@]}"
    fi
    if ((${#aur[@]})) && change "omarchy pkg aur add ${aur[*]}"; then
        omarchy pkg aur add "${aur[@]}"
    fi
    return 0
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
    if ((APPLY)) && wants theme; then
        command -v curl > /dev/null 2>&1 || die "curl not found on PATH"
    fi

    ((APPLY)) || echo "Dry run: nothing will change. Re-run with --apply to act."
    echo "rice: $RICE"
    wants packages && step_packages
    # Hooks and the files they run go in before `omarchy theme set` fires them.
    wants extras && step_extras
    wants hooks && step_hooks
    wants theme && step_theme
    wants plugins && step_plugins
    wants bar && step_bar
    wants idle && step_idle
    wants hypr && step_hypr
    wants ghostty && step_ghostty

    if ((CHANGES == 0)); then
        echo "Everything already in place."
    elif ((!APPLY)); then
        echo "$CHANGES change(s) pending; run with --apply."
    fi
}

main
