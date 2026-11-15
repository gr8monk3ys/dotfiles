#!/usr/bin/env bats
# Property tests for bin/lib/plan.sh. plan_backup exists because an earlier
# copy named backups by the second and collided when two steps ran in the
# same second; these check that it cannot return a taken name however the
# directory is already cluttered and however fast it is called. See
# test_helper/prop.bash for reproducing a failure from its seed.
#
# Invariants, for any path and any set of pre-existing backup names (files,
# directories, dangling symlinks, for this second and the next):
#   1. plan_backup never prints a path that exists (or is a dangling link);
#   2. what it prints is <path>.dotfiles-bak[...], beside <path>;
#   3. back-to-back calls, each followed by creating the name it printed,
#      never repeat a name.

load test_helper/common
load test_helper/prop

setup() {
    setup_test_env
    prop_init
    # shellcheck source=../bin/lib/plan.sh
    source "$DOTFILES_DIR/bin/lib/plan.sh"
}

teardown() {
    cleanup_test_env
}

# Create <path> as a random kind of thing that "exists" for plan_backup.
occupy() {
    prop_rand 4
    case "$REPLY" in
        0) : > "$1" ;;
        1) mkdir "$1" ;;
        2) ln -s "$TEST_TEMP_DIR/nowhere" "$1" ;;   # dangling
        3) ln -s "$TEST_TEMP_DIR" "$1" ;;
    esac
}

@test "prop: plan_backup never returns an existing path, across rapid calls in the same second" {
    local dir path name now b k calls
    for ((PROP_CASE = 1; PROP_CASE <= PROP_CASES; PROP_CASE++)); do
        dir="$TEST_TEMP_DIR/c$PROP_CASE"
        mkdir -p "$dir"
        prop_pick config "my file" .zshenv "dir.d" "a.dotfiles-bak" "x.1"
        path="$dir/$REPLY"
        prop_rand 2
        ((REPLY)) && occupy "$path"

        # Clutter: names plan_backup might try, for this second and the next.
        now="$(date +%s)"
        prop_rand 6
        for ((k = 0; k < REPLY; k++)); do
            prop_pick "" ".$now" ".$((now + 1))" ".$now.1" ".$now.2" ".$((now + 1)).1" ".$now.3"
            name="$path.dotfiles-bak$REPLY"
            [[ -e "$name" || -L "$name" ]] || occupy "$name"
        done

        local seen=" "
        prop_rand 12
        calls=$((REPLY + 2))
        for ((k = 0; k < calls; k++)); do
            b="$(plan_backup "$path")"
            [[ ! -e "$b" && ! -L "$b" ]] ||
                prop_fail "call $k for '$path' returned existing '$b' ($(ls -a "$dir" | tr '\n' ' '))" || return
            [[ "$b" == "$path.dotfiles-bak"* && "$(dirname "$b")" == "$dir" ]] ||
                prop_fail "call $k for '$path' returned '$b', not a sibling backup name" || return
            [[ "$seen" != *" $b "* ]] || prop_fail "call $k repeated '$b'" || return
            seen+="$b "
            occupy "$b"
        done
    done
}
