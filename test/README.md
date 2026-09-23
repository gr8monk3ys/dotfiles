# Test Suite

This directory contains the test suite for the dotfiles repository using
[BATS (Bash Automated Testing System)](https://github.com/bats-core/bats-core).

## Setup

```bash
make test-setup
```

One target installs everything the suite needs — bats-core, bats-support,
bats-assert, zsh and stow — with pacman, apt-get or Homebrew, whichever the
machine has. CI and both container images use it too, so there is one
install recipe rather than one per environment. Ubuntu needs 24.04 or later:
older releases ship a bats that predates `run --separate-stderr`.

## Running Tests

### Run All Tests

```bash
# From repository root
make test

# Or directly with bats
bats test
```

### Run Specific Test File

```bash
bats test/test_bin_scripts.bats
bats test/test_regressions.bats
```

### Run Specific Test

```bash
bats test/test_bin_scripts.bats -f "platform"
```

### Verbose Output

```bash
bats test --verbose-run
```

### Tap Output (for CI)

```bash
bats test --formatter tap
```

## Test Structure

```text
test/
├── README.md              # This file
├── test_bin_scripts.bats  # Tests for bin/ utility scripts
├── test_platform.bats     # Tests for platform detection
├── test_regressions.bats  # Regression tests for known breakages
├── test_packages.bats     # Tests for package file validation
└── test_helper/           # Test helpers and fixtures
    └── common.bash        # Common test functions; loads bats-support/assert
```

## Test Files

### test_bin_scripts.bats

Tests for utility scripts in `bin/`:

- Platform detection helper (platform)
- Utility scripts (dotfiles-doctor, dotfiles-update, dotfiles-backup, dotfiles-restore, dotfiles-bench-shell, dotfiles-worktree)

### test_platform.bats

Tests for platform-specific behavior:

- macOS vs Linux detection
- Architecture detection (ARM64 vs x86_64)
- Homebrew prefix detection

### test_regressions.bats

Tests for previously-fixed regressions:

- No GNU-only `find -printf` in shell configs
- No duplicate core alias declarations
- Theme consistency (`danse`, from `.config/palette/`)

### test_packages.bats

Tests for package file validation:

- Brewfile/Caskfile format
- npmfile format
- Rustfile format
- Codefile format

## Writing Tests

### Basic Test Structure

```bash
#!/usr/bin/env bats

# Load helpers
load test_helper/common

@test "description of test" {
    run command_to_test
    assert_success
    assert_output "expected output"
}
```

### Common Assertions

```bash
# Status assertions
assert_success          # Exit code 0
assert_failure          # Exit code != 0
assert_equal "$a" "$b"  # Values are equal

# Output assertions
assert_output "text"           # Exact output match
assert_output --partial "text" # Contains text
refute_output "text"           # Output doesn't contain

# File assertions
assert_file_exists "path"
assert_file_not_exists "path"
assert_symlink_to "link" "target"
```

### Setup and Teardown

```bash
setup() {
    # Run before each test
    TEST_TEMP_DIR="$(mktemp -d)"
}

teardown() {
    # Run after each test
    rm -rf "$TEST_TEMP_DIR"
}
```

## Continuous Integration

`.github/workflows/ci.yml` runs on every PR and push to `main`, each check
once and each through a make target: `make lint` (linters and validators),
`make test-setup` + `make test` + a link/unlink round-trip on macOS and
Ubuntu, `make test-docker` and `make test-docker-arch` (the Arch one runs the
real `make arch` and installs the whole pacmanfile before the suite), the real
`curl | bash` installer, and a bare `make` fresh install on macOS and Ubuntu.
`make verify` (lint, the suite, and both containers when Docker is present)
is the local equivalent — run it before pushing. On an Apple Silicon host the
Arch image runs under `linux/amd64` emulation and takes about 25 minutes;
`SKIP_ARCH_DOCKER=1` drops it locally without losing the CI coverage.

## Test Coverage

### Current Coverage

- [x] Platform detection scripts
- [x] Utility script help flags
- [x] Package file validation
- [x] Regression guards for known breakages
- [ ] Makefile targets

### Coverage Goals

- Unit tests for all bin/ scripts
- Integration tests for installation process
- Validation tests for all configuration files
- Cross-platform testing (macOS, Linux)

## Best Practices

1. **Keep tests fast** - Use mocking when possible
2. **Test one thing** - Each test should verify one behavior
3. **Use descriptive names** - Test names should explain what they verify
4. **Clean up** - Always clean up test artifacts in teardown
5. **Mock external dependencies** - Don't rely on network or external services
6. **Test edge cases** - Include tests for error conditions

## Troubleshooting

### Tests Not Running

```bash
# Check BATS installation
which bats
bats --version

# Check test file permissions
ls -l test/*.bats

# Make test files executable if needed
chmod +x test/*.bats
```

### Test Failures

```bash
# Run with verbose output
bats test --verbose-run

# Run specific failing test
bats test/test_name.bats -f "failing test"

# Check test environment
env | grep -E "(DOTFILES|HOME|PATH)"
```

### Helper Libraries Not Found

`test_helper/common.bash` loads bats-support and bats-assert from the
Homebrew or distro location and falls back to a minimal shim without them.
Run `make test-setup` to install the real libraries.

## Resources

- [BATS Documentation](https://bats-core.readthedocs.io/)
- [BATS GitHub](https://github.com/bats-core/bats-core)
- [BATS Tutorial](https://bats-core.readthedocs.io/en/stable/tutorial.html)
- [Writing Good Tests](https://bats-core.readthedocs.io/en/stable/writing-tests.html)

## Contributing

When adding new features:

1. Write tests first (TDD approach)
2. Ensure tests pass before submitting PR
3. Maintain test coverage above 80%
4. Update this README if adding new test files
