# GitHub Workflows

This directory contains GitHub Actions workflows for continuous integration and automated testing.

## Workflows

### 🔨 [install.yml](workflows/install.yml)
**Dotfiles Installation Workflow**

Tests the full installation process on multiple platforms.

**Triggers:**
- Every push to repository
- Scheduled: Every Thursday at 5:00 PM (weekly smoke test)

**Platforms Tested:**
- macOS 14 (Intel/Apple Silicon)
- macOS 15 (latest)
- Ubuntu (latest)

**What it does:**
1. Cleans up pre-installed software (macOS only)
2. Clones the repository
3. Runs full installation via `make`
4. Verifies shell setup
5. Runs health check via `make doctor`
6. Installs BATS and runs test suite

**Badge:** [![Installation](https://github.com/gr8monk3ys/dotfiles/workflows/Dotfiles%20Installation/badge.svg)](https://github.com/gr8monk3ys/dotfiles/actions/workflows/install.yml)

### ✅ [test.yml](workflows/test.yml)
**Test Workflow**

Runs BATS test suite and integration tests.

**Triggers:**
- Push to main branch
- Pull requests to main branch

**Jobs:**

**1. BATS Tests** (macOS & Ubuntu)
- Platform detection tests
- bin/ script tests
- Package file validation tests

**2. Integration Tests** (macOS only)
- Symlink creation/deletion
- Make target functionality

**Badge:** [![Tests](https://github.com/gr8monk3ys/dotfiles/workflows/Tests/badge.svg)](https://github.com/gr8monk3ys/dotfiles/actions/workflows/test.yml)

### 🔍 [lint.yml](workflows/lint.yml)
**Linting Workflow**

Validates code quality and format.

**Triggers:**
- Push to main branch
- Pull requests to main branch

**Jobs:**

**1. ShellCheck**
- Lints all shell scripts in `bin/`
- Uses .shellcheckrc configuration
- Severity: warning level

**2. Markdownlint**
- Validates all Markdown files
- Checks formatting consistency
- Uses .markdownlint.json config (if present)

**3. Package File Validation**
- Validates Brewfile format
- Validates npmfile format
- Validates Rustfile format
- Verifies all package files exist

**Badge:** [![Lint](https://github.com/gr8monk3ys/dotfiles/workflows/Lint/badge.svg)](https://github.com/gr8monk3ys/dotfiles/actions/workflows/lint.yml)

## Workflow Status

View all workflow runs: [Actions Tab](https://github.com/gr8monk3ys/dotfiles/actions)

## Local Testing

Before pushing changes, test locally:

```bash
# Run health check
make doctor

# Run tests
make test

# Run linters
shellcheck bin/*
markdownlint **/*.md
```

## Adding New Workflows

1. Create new workflow file in `.github/workflows/`
2. Follow YAML syntax and GitHub Actions format
3. Test workflow locally if possible
4. Document in this README
5. Add badge to main README.md

## Common Workflow Patterns

### Basic Structure

```yaml
name: Workflow Name

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  job_name:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Step name
        run: command
```

### Matrix Testing

```yaml
strategy:
  matrix:
    os: [macos-latest, ubuntu-latest]
runs-on: ${{ matrix.os }}
```

### Conditional Steps

```yaml
- name: macOS only step
  if: runner.os == 'macOS'
  run: brew install something
```

## Troubleshooting

### Workflow Fails

1. Check workflow run logs in Actions tab
2. Look for specific error messages
3. Test the failing command locally
4. Update workflow and push fix

### BATS Tests Fail

1. Run tests locally: `make test`
2. Fix failing tests
3. Verify tests pass locally before pushing

### Linting Errors

1. Run linter locally: `shellcheck bin/*`
2. Fix reported issues
3. Push corrected code

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Actions Marketplace](https://github.com/marketplace?type=actions)
- [Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)

## Future Improvements

- [ ] Add dependency update automation (Dependabot)
- [ ] Add broken link checker
- [ ] Add documentation validation
- [ ] Add security scanning
- [ ] Add release automation
