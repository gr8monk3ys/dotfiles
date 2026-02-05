# Test Suite

This directory contains the test suite for the dotfiles repository using
[BATS (Bash Automated Testing System)](https://github.com/bats-core/bats-core).

## Setup

### Install BATS

**macOS (via Homebrew):**

```bash
brew install bats-core
```

**Linux:**

```bash
# Arch Linux
sudo pacman -S bats

# Ubuntu/Debian
sudo apt-get install bats

# Or install from source
git clone https://github.com/bats-core/bats-core.git
cd bats-core
./install.sh /usr/local
```

### Install BATS Helpers (Optional but Recommended)

```bash
# Install bats-support (helper functions)
git clone https://github.com/bats-core/bats-support.git test/test_helper/bats-support

# Install bats-assert (assertions)
git clone https://github.com/bats-core/bats-assert.git test/test_helper/bats-assert

# Install bats-file (file assertions)
git clone https://github.com/bats-core/bats-file.git test/test_helper/bats-file
```

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
bats test/test_symlinks.bats
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
├── test_symlinks.bats     # Tests for symlink creation/deletion
├── test_platform.bats     # Tests for platform detection
├── test_packages.bats     # Tests for package file validation
└── test_helper/           # Test helpers and fixtures
    ├── common.bash        # Common test functions
    ├── bats-support/      # BATS support library
    ├── bats-assert/       # BATS assertion library
    └── bats-file/         # BATS file assertion library
```

## Test Files

### test_bin_scripts.bats

Tests for utility scripts in `bin/`:

- Platform detection helper (platform)
- Executable checker (is-executable)
- Utility scripts (dotfiles-doctor, dotfiles-update, dotfiles-backup)

### test_symlinks.bats

Tests for symlink management:

- Link creation and deletion
- Backup handling
- Error conditions

### test_platform.bats

Tests for platform-specific behavior:

- macOS vs Linux detection
- Architecture detection (ARM64 vs x86_64)
- Homebrew prefix detection

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

Tests are automatically run in CI/CD pipelines:

```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install BATS
        run: brew install bats-core
      - name: Run tests
        run: make test
```

## Test Coverage

### Current Coverage

- [x] Platform detection scripts
- [x] Utility script help flags
- [ ] Symlink creation/deletion
- [ ] Makefile targets
- [ ] Package file validation

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

```bash
# Reinstall helpers
rm -rf test/test_helper/bats-*
git clone https://github.com/bats-core/bats-support.git test/test_helper/bats-support
git clone https://github.com/bats-core/bats-assert.git test/test_helper/bats-assert
git clone https://github.com/bats-core/bats-file.git test/test_helper/bats-file
```

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
