#!/usr/bin/env bats
# Unit tests for bin/validate-doc-links using synthetic fixture trees.
#
# The real repo tree is already exercised by `make verify-doc-links`; these
# tests target the script's parsing/resolution logic directly (fenced-code
# skipping, external-link skipping, anchor/query stripping, absolute vs.
# relative resolution) against disposable fixtures so they don't depend on
# the current state of the repo's own markdown.

load test_helper/common

setup() {
    setup_test_env
}

teardown() {
    cleanup_test_env
}

@test "validate-doc-links: passes when all local links resolve" {
    mkdir -p "$TEST_TEMP_DIR/docs/sub"
    printf 'target\n' > "$TEST_TEMP_DIR/docs/sub/target.md"
    cat > "$TEST_TEMP_DIR/docs/README.md" <<'EOF'
See [good link](sub/target.md).
Absolute style: [abs](/sub/target.md)
Query/anchor stripped: [q](sub/target.md?x=1#y)
EOF

    run bash "$DOTFILES_DIR/bin/validate-doc-links" "$TEST_TEMP_DIR/docs"
    assert_success
    assert_output --partial "Markdown links are valid"
}

@test "validate-doc-links: reports a broken relative link and fails" {
    mkdir -p "$TEST_TEMP_DIR/docs"
    cat > "$TEST_TEMP_DIR/docs/README.md" <<'EOF'
See [broken](sub/missing.md).
EOF

    run bash "$DOTFILES_DIR/bin/validate-doc-links" "$TEST_TEMP_DIR/docs"
    assert_failure
    assert_output --partial "Broken markdown link: README.md -> sub/missing.md"
}

@test "validate-doc-links: ignores links inside fenced code blocks" {
    mkdir -p "$TEST_TEMP_DIR/docs"
    cat > "$TEST_TEMP_DIR/docs/README.md" <<'EOF'
Real link: [ok](exists.md)

```
[not a real link](does/not/exist.md)
```
EOF
    printf 'exists\n' > "$TEST_TEMP_DIR/docs/exists.md"

    run bash "$DOTFILES_DIR/bin/validate-doc-links" "$TEST_TEMP_DIR/docs"
    assert_success
}

@test "validate-doc-links: ignores external, mailto, and anchor-only links" {
    mkdir -p "$TEST_TEMP_DIR/docs"
    cat > "$TEST_TEMP_DIR/docs/README.md" <<'EOF'
[gh](https://github.com/example/example)
[site](http://example.com)
[mail](mailto:person@example.com)
[section](#some-heading)
EOF

    run bash "$DOTFILES_DIR/bin/validate-doc-links" "$TEST_TEMP_DIR/docs"
    assert_success
}

@test "validate-doc-links: resolves absolute-style links against ROOT_DIR, not the file's directory" {
    mkdir -p "$TEST_TEMP_DIR/docs/nested"
    printf 'target\n' > "$TEST_TEMP_DIR/docs/top-level.md"
    cat > "$TEST_TEMP_DIR/docs/nested/page.md" <<'EOF'
[abs](/top-level.md)
EOF

    run bash "$DOTFILES_DIR/bin/validate-doc-links" "$TEST_TEMP_DIR/docs"
    assert_success
}

@test "validate-doc-links: flags broken image references the same as links" {
    mkdir -p "$TEST_TEMP_DIR/docs"
    cat > "$TEST_TEMP_DIR/docs/README.md" <<'EOF'
![missing image](img/missing.png)
EOF

    run bash "$DOTFILES_DIR/bin/validate-doc-links" "$TEST_TEMP_DIR/docs"
    assert_failure
    assert_output --partial "Broken markdown link: README.md -> img/missing.png"
}

@test "validate-doc-links: fails cleanly when ROOT_DIR does not exist" {
    run bash "$DOTFILES_DIR/bin/validate-doc-links" "$TEST_TEMP_DIR/no-such-dir"
    assert_failure
    assert_output --partial "no-such-dir"
}
