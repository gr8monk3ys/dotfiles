# Minimal fixture used by test_alias_checker.bats: every alias here MUST
# resolve cleanly against builtins, the test allowlist, and the install
# manifests in install/. This fixture is the positive case.

alias gg="echo git-status-placeholder"
alias e="echo hello"

if command -v eza &> /dev/null; then
    alias ll="eza -la"
fi
