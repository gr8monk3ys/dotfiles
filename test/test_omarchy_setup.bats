#!/usr/bin/env bats
# omarchy/ - the Omarchy layer: pinned plugin manifest, bar layout, and
# omarchy/setup.sh (dry run by default). Every Omarchy marker and the
# `omarchy` command are faked, so this runs the same on any machine.

load test_helper/common

SETUP="$DOTFILES_DIR/omarchy/setup.sh"

setup() {
    setup_test_env
    export HOME="$TEST_HOME"
    export XDG_CONFIG_HOME="$TEST_HOME/.config"
    export XDG_STATE_HOME="$TEST_HOME/.local/state"
    export PLATFORM_OS_RELEASE="$TEST_TEMP_DIR/os-release"
    export PLATFORM_OMARCHY_SYSTEM_DIR="$TEST_TEMP_DIR/usr-share-omarchy"
    export OMARCHY_BIN_DIR="$TEST_HOME/.local/bin"
    export XDG_DATA_HOME="$TEST_HOME/.local/share"
    # The older tests were written against Monochrome 43; Field Notebook
    # tests set their own rice.
    export OMARCHY_RICE=monochrome-43
    : > "$PLATFORM_OS_RELEASE"

    # A logging stand-in for the omarchy CLI.
    STUB_BIN="$TEST_TEMP_DIR/bin"
    OMARCHY_LOG="$TEST_TEMP_DIR/omarchy.log"
    export OMARCHY_LOG
    mkdir -p "$STUB_BIN"
    cat > "$STUB_BIN/omarchy" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$OMARCHY_LOG"
case "$1 $2" in
    "plugin list") echo '[]' ;;
    "theme dir") exit 1 ;;
esac
STUB
    chmod +x "$STUB_BIN/omarchy"
    export PATH="$STUB_BIN:$PATH"
}

teardown() {
    cleanup_test_env
}

be_omarchy() { mkdir -p "$PLATFORM_OMARCHY_SYSTEM_DIR"; }

@test "setup.sh dry run on a non-Omarchy machine does nothing and succeeds" {
    run "$SETUP"
    assert_success
    assert_output --partial "Not an Omarchy machine"
    [[ -z "$(ls -A "$TEST_HOME")" ]]
}

@test "setup.sh --apply on a non-Omarchy machine refuses" {
    run "$SETUP" --apply
    assert_failure
    [[ -z "$(ls -A "$TEST_HOME")" ]]
}

@test "setup.sh dry run on Omarchy writes nothing and calls no mutating command" {
    be_omarchy
    run "$SETUP"
    assert_success
    assert_output --partial "Dry run"
    assert_output --partial "would"
    [[ -z "$(ls -A "$TEST_HOME")" ]]
    # Only read-only queries reached the CLI.
    run grep -vE '^(plugin list --json|theme dir vantablack)$' "$OMARCHY_LOG"
    assert_output ""
}

@test "setup.sh rejects an unknown step" {
    run "$SETUP" --only everything
    assert_failure
}

@test "hypr step links the snippet and appends the require exactly once" {
    be_omarchy
    mkdir -p "$XDG_CONFIG_HOME/hypr"
    echo '-- user look' > "$XDG_CONFIG_HOME/hypr/looknfeel.lua"
    run "$SETUP" --apply --only hypr
    assert_success
    run "$SETUP" --apply --only hypr
    assert_success
    assert_output --partial "Everything already in place"
    run grep -c 'require("hypr.monochrome_43")' "$XDG_CONFIG_HOME/hypr/looknfeel.lua"
    assert_output "1"
    [[ "$(readlink "$XDG_CONFIG_HOME/hypr/monochrome_43.lua")" == "$DOTFILES_DIR/omarchy/rices/monochrome-43/hypr.lua" ]]
}

@test "hypr step does not stack a require on top of an inline copy" {
    be_omarchy
    mkdir -p "$XDG_CONFIG_HOME/hypr"
    printf 'hl.curve("riceOut", {})\n' > "$XDG_CONFIG_HOME/hypr/looknfeel.lua"
    run "$SETUP" --apply --only hypr
    assert_success
    run grep -c 'require("hypr.monochrome_43")' "$XDG_CONFIG_HOME/hypr/looknfeel.lua"
    assert_output "0"
}

@test "an external plugin's directory is never touched or enabled" {
    be_omarchy
    local plugins="$XDG_CONFIG_HOME/omarchy/plugins"
    mkdir -p "$plugins/someone.widget"
    echo '{"id": "someone.widget"}' > "$plugins/someone.widget/manifest.json"
    printf 'someone.widget\texternal\t-\tyes\n' > "$TEST_TEMP_DIR/plugins.tsv"
    OMARCHY_PLUGINS_TSV="$TEST_TEMP_DIR/plugins.tsv" run "$SETUP" --apply --only plugins
    assert_success
    assert_output --partial "external, not managed here"
    [[ -d "$plugins/someone.widget" && ! -L "$plugins/someone.widget" ]]
    run ls -A "$XDG_CONFIG_HOME/omarchy"
    assert_output "plugins"
    run grep -vE '^plugin list --json$' "$OMARCHY_LOG"
    assert_output ""
}

@test "bar step replaces only .bar.layout, keeps key order, and backs up by epoch" {
    command -v jq > /dev/null || skip "jq not installed"
    be_omarchy
    local cfg="$XDG_CONFIG_HOME/omarchy"
    mkdir -p "$cfg"
    printf '{"zeta": 1, "bar": {"position": "left", "layout": {"x": 1}, "a": 2}, "alpha": 3}\n' > "$cfg/shell.json"
    : > "$cfg/shell.json.dotfiles-bak"
    run "$SETUP" --apply --only bar
    assert_success
    run jq -c 'keys_unsorted' "$cfg/shell.json"
    assert_output '["zeta","bar","alpha"]'
    run jq -c '.bar | keys_unsorted' "$cfg/shell.json"
    assert_output '["position","layout","a"]'
    [[ "$(jq -c .bar.layout "$cfg/shell.json")" == "$(jq -c .layout "$DOTFILES_DIR/omarchy/bar.json")" ]]
    # The older plain backup is left alone; a new epoch-stamped one holds the original.
    [[ ! -s "$cfg/shell.json.dotfiles-bak" ]]
    run bash -c 'jq -c .bar.layout "$1"/shell.json.dotfiles-bak.[0-9]*' _ "$cfg"
    assert_output '{"x":1}'
}

@test "plugins.tsv pins every third-party plugin to a full commit over https" {
    run bash -c '
        status=0
        while read -r id src commit enable; do
            [[ -z "$id" || "$id" == \#* ]] && continue
            [[ "$enable" =~ ^(yes|no)$ ]] || { echo "$id: enable must be yes|no"; status=1; }
            if [[ "$src" == external ]]; then
                [[ "$commit" == - && "$enable" == no ]] || { echo "$id: external takes - and no"; status=1; }
            else
                [[ "$src" =~ ^https://github\.com/[^/]+/[^/]+\.git$ ]] || { echo "$id: bad source $src"; status=1; }
                [[ "$commit" =~ ^[0-9a-f]{40}$ ]] || { echo "$id: commit not pinned: $commit"; status=1; }
            fi
        done < "$1/omarchy/plugins.tsv"
        exit $status
    ' _ "$DOTFILES_DIR"
    assert_success
}

@test "bar.json only places built-in widgets or plugins the manifest installs" {
    command -v jq > /dev/null || skip "jq not installed"
    run bash -c '
        ids="$(awk "!/^#/ && NF { print \$1 }" "$1/omarchy/plugins.tsv")"
        status=0
        for w in $(jq -r ".layout[][] | .id" "$1/omarchy/bar.json"); do
            [[ "$w" == omarchy.* ]] && continue
            printf "%s\n" "$ids" | grep -Fxq "$w" || { echo "bar.json places $w, which plugins.tsv does not install"; status=1; }
        done
        exit $status
    ' _ "$DOTFILES_DIR"
    assert_success
}

@test "ghostty step appends the include to config.local exactly once" {
    be_omarchy
    export OMARCHY_GHOSTTY_ZSH="$STUB_BIN/omarchy" # any executable will do
    mkdir -p "$XDG_CONFIG_HOME/ghostty"
    echo 'theme = danse' > "$XDG_CONFIG_HOME/ghostty/config.local"
    run "$SETUP" --apply --only ghostty
    assert_success
    run "$SETUP" --apply --only ghostty
    assert_output --partial "Everything already in place"
    run grep -c "^config-file = $DOTFILES_DIR/omarchy/ghostty.conf\$" "$XDG_CONFIG_HOME/ghostty/config.local"
    assert_output "1"
    # The user's own lines survive.
    grep -qx 'theme = danse' "$XDG_CONFIG_HOME/ghostty/config.local"
}

@test "ghostty step makes Omarchy's own config read config.local, once" {
    be_omarchy
    export OMARCHY_GHOSTTY_ZSH="$STUB_BIN/omarchy" # any executable will do
    mkdir -p "$XDG_CONFIG_HOME/ghostty"
    echo 'font-size = 9' > "$XDG_CONFIG_HOME/ghostty/config"
    run "$SETUP" --apply --only ghostty
    assert_success
    run "$SETUP" --apply --only ghostty
    assert_output --partial "Everything already in place"
    run grep -c '^config-file = ?"config.local"$' "$XDG_CONFIG_HOME/ghostty/config"
    assert_output "1"
    grep -qx 'font-size = 9' "$XDG_CONFIG_HOME/ghostty/config"
}

@test "ghostty step leaves Ghostty alone while zsh is missing" {
    be_omarchy
    export OMARCHY_GHOSTTY_ZSH="$TEST_TEMP_DIR/no-such-zsh"
    run "$SETUP" --apply --only ghostty
    assert_success
    assert_output --partial "not found"
    [[ ! -e "$XDG_CONFIG_HOME/ghostty/config.local" ]]
}

@test "omarchy/ghostty.conf runs zsh and is valid Ghostty config" {
    grep -qx 'command = /usr/bin/zsh' "$DOTFILES_DIR/omarchy/ghostty.conf"
    command -v ghostty > /dev/null || skip "ghostty not installed"
    run ghostty +validate-config --config-file="$DOTFILES_DIR/omarchy/ghostty.conf"
    assert_success
}

# ---------------------------------------------------------------------------
# Rice selection and the Field Notebook steps
# ---------------------------------------------------------------------------

@test "every Omarchy rice in the Rice module has a rice directory, and no other directory exists" {
    run bash -c '. "$1/.config/palette/rice.sh"; diff <(rice_list omarchy | sort) <(ls "$1/omarchy/rices" | sort)' _ "$DOTFILES_DIR"
    assert_success
}

@test "rice.local picks the rice; --rice overrides it for one run" {
    be_omarchy
    mkdir -p "$XDG_CONFIG_HOME/palette"
    echo monochrome-43 > "$XDG_CONFIG_HOME/palette/rice.local"
    unset OMARCHY_RICE
    run "$SETUP" --only extras
    assert_output --partial "rice: monochrome-43"
    run "$SETUP" --only extras --rice field-notebook
    assert_output --partial "rice: field-notebook"
}

@test "setup.sh rejects an unknown rice" {
    run "$SETUP" --rice vaporwave
    assert_failure
    assert_output --partial "unknown rice"
}

@test "every rice directory ships a theme and a Hyprland module" {
    local d
    for d in "$DOTFILES_DIR"/omarchy/rices/*/; do
        [[ -f "$d/theme/colors.toml" && -f "$d/theme/icons.theme" && -f "$d/hypr.lua" ]] ||
            { echo "incomplete rice: $d"; return 1; }
        [[ ! -e "$d/backgrounds" || -x "$d/backgrounds" ]] || { echo "$d/backgrounds not executable"; return 1; }
    done
}

@test "field-notebook hypr step links the module and night light, requires once" {
    be_omarchy
    export OMARCHY_RICE=field-notebook
    mkdir -p "$XDG_CONFIG_HOME/hypr"
    echo '-- user look' > "$XDG_CONFIG_HOME/hypr/looknfeel.lua"
    run "$SETUP" --apply --only hypr
    assert_success
    run "$SETUP" --apply --only hypr
    assert_output --partial "Everything already in place"
    run grep -c 'require("hypr.field_notebook")' "$XDG_CONFIG_HOME/hypr/looknfeel.lua"
    assert_output "1"
    [[ "$(readlink "$XDG_CONFIG_HOME/hypr/field_notebook.lua")" == "$DOTFILES_DIR/omarchy/rices/field-notebook/hypr.lua" ]]
    [[ "$(readlink "$XDG_CONFIG_HOME/hypr/hyprsunset.conf")" == "$DOTFILES_DIR/omarchy/rices/field-notebook/hypr/hyprsunset.conf" ]]
}

@test "field-notebook hypr step does not stack a require on an inline copy" {
    be_omarchy
    export OMARCHY_RICE=field-notebook
    mkdir -p "$XDG_CONFIG_HOME/hypr"
    printf 'hl.curve("notebook", {})\n' > "$XDG_CONFIG_HOME/hypr/looknfeel.lua"
    run "$SETUP" --apply --only hypr
    assert_success
    assert_output --partial "inline copy"
    run grep -c 'require("hypr.field_notebook")' "$XDG_CONFIG_HOME/hypr/looknfeel.lua"
    assert_output "0"
}

@test "idle step replaces only .idle and keeps key order" {
    command -v jq > /dev/null || skip "jq not installed"
    be_omarchy
    local cfg="$XDG_CONFIG_HOME/omarchy"
    mkdir -p "$cfg"
    printf '{"bar": {"position": "left"}, "idle": {"lock": 300, "screensaver": 150}, "version": 1}\n' > "$cfg/shell.json"
    run "$SETUP" --apply --only idle
    assert_success
    run jq -c 'keys_unsorted' "$cfg/shell.json"
    assert_output '["bar","idle","version"]'
    [[ "$(jq -S -c .idle "$cfg/shell.json")" == "$(jq -S -c . "$DOTFILES_DIR/omarchy/idle.json")" ]]
    run "$SETUP" --apply --only idle
    assert_output --partial "Everything already in place"
}

@test "hooks step links the shared hooks, and Field Notebook's only for that rice" {
    be_omarchy
    local hooks="$XDG_CONFIG_HOME/omarchy/hooks/theme-set.d"
    run "$SETUP" --apply --only hooks
    assert_success
    [[ -L "$hooks/10-owe-sync" ]]
    [[ ! -e "$hooks/20-field-notebook-apps" ]]
    OMARCHY_RICE=field-notebook run "$SETUP" --apply --only hooks
    assert_success
    [[ "$(readlink "$hooks/20-field-notebook-apps")" == "$DOTFILES_DIR/omarchy/rices/field-notebook/hooks/theme-set.d/20-field-notebook-apps" ]]
}

@test "extras step links the session scripts, shared files and screensaver art" {
    be_omarchy
    export OMARCHY_RICE=field-notebook
    run "$SETUP" --apply --only extras
    assert_success
    local f
    for f in "$DOTFILES_DIR"/omarchy/rices/field-notebook/bin/*; do
        [[ "$(readlink "$OMARCHY_BIN_DIR/$(basename "$f")")" == "$f" ]]
    done
    [[ -L "$XDG_DATA_HOME/field-notebook/themed.py" ]]
    [[ -L "$XDG_CONFIG_HOME/omarchy/branding/screensaver.txt" ]]
    run "$SETUP" --apply --only extras
    assert_output --partial "Everything already in place"
}

@test "packages step installs only what pacman lacks, repo and AUR apart" {
    be_omarchy
    export OMARCHY_RICE=field-notebook
    # pacman knows onefetch and nothing else.
    printf '#!/usr/bin/env bash\n[[ "$2" == onefetch ]]\n' > "$STUB_BIN/pacman"
    chmod +x "$STUB_BIN/pacman"
    run "$SETUP" --apply --only packages
    assert_success
    run grep -c '^pkg add ' "$OMARCHY_LOG"
    assert_output "1"
    run grep -c '^pkg aur add ' "$OMARCHY_LOG"
    assert_output "1"
    run grep -E "^pkg (aur )?add .*\\bonefetch\\b" "$OMARCHY_LOG"
    assert_failure
    grep -q '^pkg aur add .*gh-dash-bin' "$OMARCHY_LOG"
}

@test "packages step is a no-op for Monochrome 43" {
    be_omarchy
    run "$SETUP" --apply --only packages
    assert_success
    [[ ! -s "$OMARCHY_LOG" ]] || ! grep -q '^pkg ' "$OMARCHY_LOG"
}

@test "rice packages never repeat what pacmanfile already installs" {
    run bash -c 'comm -12 <("$1/bin/manifest" list pacman | sort) <({ "$1/bin/manifest" list rice-pacman; "$1/bin/manifest" list rice-aur; } | sort)' _ "$DOTFILES_DIR"
    assert_success
    assert_output ""
}

@test "bar and idle in one run each get their own shell.json backup" {
    command -v jq > /dev/null || skip "jq not installed"
    be_omarchy
    local cfg="$XDG_CONFIG_HOME/omarchy"
    mkdir -p "$cfg"
    printf '{"bar": {"position": "left", "layout": {}}, "idle": {"lock": 300}}\n' > "$cfg/shell.json"
    run "$SETUP" --apply --only bar
    assert_success
    run "$SETUP" --apply --only idle
    assert_success
    # BSD wc pads its count with spaces; strip them.
    run bash -c 'ls "$1"/shell.json.dotfiles-bak* | wc -l | tr -d " "' _ "$cfg"
    assert_output "2"
}

@test "switching rice swaps the Hyprland require instead of stacking it" {
    be_omarchy
    mkdir -p "$XDG_CONFIG_HOME/hypr"
    echo '-- user look' > "$XDG_CONFIG_HOME/hypr/looknfeel.lua"
    OMARCHY_RICE=field-notebook run "$SETUP" --apply --only hypr
    assert_success
    OMARCHY_RICE=monochrome-43 run "$SETUP" --apply --only hypr
    assert_success
    run grep -c 'require("hypr\.' "$XDG_CONFIG_HOME/hypr/looknfeel.lua"
    assert_output "1"
    grep -qx 'require("hypr.monochrome_43")' "$XDG_CONFIG_HOME/hypr/looknfeel.lua"
    grep -qx -- '-- user look' "$XDG_CONFIG_HOME/hypr/looknfeel.lua"
}

@test "a plugin marked no is disabled when it is enabled" {
    be_omarchy
    local dir="$XDG_CONFIG_HOME/omarchy/plugins/someone.widget" head
    mkdir -p "$dir"
    git -C "$dir" init -q
    git -C "$dir" -c user.name=t -c user.email=t@example.invalid commit -q --allow-empty -m init
    head="$(git -C "$dir" rev-parse HEAD)"
    cat > "$STUB_BIN/omarchy" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$OMARCHY_LOG"
[[ "$1 $2" == "plugin list" ]] && echo '[{"id": "someone.widget", "enabled": true}]'
exit 0
STUB
    printf 'someone.widget\thttps://github.com/someone/widget.git\t%s\tno\n' "$head" > "$TEST_TEMP_DIR/plugins.tsv"
    OMARCHY_PLUGINS_TSV="$TEST_TEMP_DIR/plugins.tsv" run "$SETUP" --apply --only plugins
    assert_success
    grep -qx 'plugin disable someone.widget' "$OMARCHY_LOG"
}
