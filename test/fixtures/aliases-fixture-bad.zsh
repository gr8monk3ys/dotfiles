# Negative fixture: contains an unresolved reference outside any guard.
# `definitely-not-a-real-tool` is not in any manifest, builtin list,
# or allowlist — the checker MUST flag this.

alias bad="definitely-not-a-real-tool --frob"
