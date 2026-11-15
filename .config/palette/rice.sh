# rice.sh - which Rice a machine shows, for every consumer that cares.
#
# Sourced, never executed, by POSIX sh, bash and zsh alike: sketchybar and
# borders (minimal PATH, so no bin/ helper), the shell (.config/zsh/rice.zsh,
# on the startup path, so builtins only and no command substitution), and
# omarchy/setup.sh. Before this file each of them carried its own parser of
# rice.local with its own idea of the default.
#
# The Rice table (name, where it ships, its palette file):
#
#   monochrome-43   macos omarchy   palette/monochrome-43.conf   default on macOS
#   danse           macos           palette/danse.conf
#   field-notebook  omarchy         palette/field-notebook.conf  default on Omarchy
#
# Selection: one word in ~/.config/palette/rice.local (gitignored, per
# machine). A rice that does not ship on the platform asked about, an unknown
# word, or no file at all gives that platform's default.
#
# Interface:
#   rice_select [platform]       sets RICE. No argument: this machine's
#                                platform, from rice_platform. An explicit
#                                empty argument ("") means "any platform".
#   rice_platform                sets RICE_PLATFORM (macos | omarchy | empty
#                                for anything else) unless it is already set:
#                                the override for tests and odd machines
#   rice_available <rice> [platform]   true if <rice> ships there
#   rice_default [platform]      sets RICE to the platform default
#   rice_list [platform]         prints the rices, one per line
#
# A rice's palette file is palette/<rice>.conf, and its role map (which of
# its colours fills each danse-named role in the tool templates) is
# palette/<rice>.roles; see bin/rice-themes.

rice_available() {
    case "$1:${2:-}" in
        monochrome-43:macos | monochrome-43:omarchy | monochrome-43:) return 0 ;;
        danse:macos | danse:) return 0 ;;
        field-notebook:omarchy | field-notebook:) return 0 ;;
    esac
    return 1
}

rice_default() {
    case "${1:-}" in
        omarchy) RICE=field-notebook ;;
        *) RICE=monochrome-43 ;;
    esac
}

rice_list() {
    for _rice in monochrome-43 danse field-notebook; do
        rice_available "$_rice" "${1:-}" && printf '%s\n' "$_rice"
    done
    unset _rice
    return 0
}

# Builtins only (no uname, no command substitution): the shell calls this on
# its startup path. The Omarchy markers are bin/platform's; /System/Library
# exists only on macOS.
rice_platform() {
    [ "${RICE_PLATFORM+set}" = set ] && return 0
    if [ -d /usr/share/omarchy ] || [ -d "$HOME/.local/share/omarchy" ]; then
        RICE_PLATFORM=omarchy
    elif [ -d /System/Library/CoreServices ]; then
        RICE_PLATFORM=macos
    else
        RICE_PLATFORM=""
    fi
}

rice_select() {
    if [ $# -eq 0 ]; then
        rice_platform
        set -- "$RICE_PLATFORM"
    fi
    RICE=""
    _rice_file="${XDG_CONFIG_HOME:-$HOME/.config}/palette/rice.local"
    if [ -r "$_rice_file" ]; then
        read -r RICE < "$_rice_file" || true
    fi
    unset _rice_file
    rice_available "$RICE" "${1:-}" || rice_default "${1:-}"
}
