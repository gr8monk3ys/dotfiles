# Exemption fixture: the alias body references a deliberately unresolvable
# command, but it lives inside an `if command -v` block. The checker MUST
# treat it as exempt and pass with no violations.
#
# If the depth-counter logic breaks, this fixture would fail (the alias's
# first word cannot be resolved by any other means).

if command -v definitely-not-installed-tool &> /dev/null; then
    alias x="definitely-not-installed-tool --frob"
fi
