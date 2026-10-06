#!/usr/bin/env bats
# Static checks on tracked tool configs that bin/validate-config-live cannot
# probe live. Each says why a text check is the proportionate tool.

load test_helper/common

# Regression: yazi renamed [manager] to [mgr] in 25.4 and [open].rules' `name`
# key to `url`. Our config kept the old spellings, so yazi failed to parse it
# and ran on stock defaults while appearing configured. This is a text check,
# not a liveness one — yazi has no headless config probe, `--debug` needs a
# TTY, and supplying one via `script` hangs on the TUI.
@test "yazi config uses the section names this yazi version knows" {
    command -v yazi > /dev/null 2>&1 || skip "yazi not installed"
    run grep -c '^\[manager\]' .config/yazi/yazi.toml
    assert_output "0"
    run grep -c '^\[mgr\]' .config/yazi/yazi.toml
    assert_output "1"
    # Every [open].rules entry needs url or mime; `name` was the old key.
    run grep -c '{ name = ' .config/yazi/yazi.toml
    assert_output "0"
}
