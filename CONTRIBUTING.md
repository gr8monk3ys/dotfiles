# Contributing to Dotfiles

Thank you for your interest in contributing! This document provides guidelines for contributing to this dotfiles repository.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Documentation](#documentation)
- [Pull Request Process](#pull-request-process)

## Code of Conduct

- Be respectful and constructive
- Focus on what's best for the community
- Show empathy towards other contributors
- Accept constructive criticism gracefully

## Getting Started

1. **Fork the repository**
   ```bash
   # Click the "Fork" button on GitHub
   ```

2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR_USERNAME/dotfiles.git
   cd dotfiles
   ```

3. **Add upstream remote**
   ```bash
   git remote add upstream https://github.com/gr8monk3ys/dotfiles.git
   ```

4. **Create a branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

## How to Contribute

### Reporting Bugs

- Check existing issues first to avoid duplicates
- Use a clear, descriptive title
- Describe the steps to reproduce
- Include your environment details (OS version, shell version, etc.)
- Provide relevant configuration files or logs

### Suggesting Enhancements

- Check TODO.md to see if it's already planned
- Use a clear, descriptive title
- Explain why this enhancement would be useful
- Provide examples of how it would work

### Adding New Configurations

1. Place configurations in appropriate `.config/[app-name]/` directory
2. Create a README.md explaining the configuration
3. Update main README.md if it's a major tool
4. Add any required packages to install/ files

### Improving Documentation

- Fix typos, improve clarity, add examples
- Keep documentation up-to-date with code changes
- Follow the existing documentation style
- Add README.md files to new directories

## Development Workflow

### Branch Naming Convention

Use descriptive branch names with prefixes:
- `feature/` - New features or enhancements
- `fix/` - Bug fixes
- `docs/` - Documentation changes
- `refactor/` - Code refactoring
- `test/` - Adding or updating tests
- `chore/` - Maintenance tasks

Examples:
- `feature/add-zsh-plugins`
- `fix/broken-symlink-creation`
- `docs/update-installation-guide`

### Commit Message Format

Follow conventional commit format:

```
<type>: <subject>

<body (optional)>

<footer (optional)>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, no logic change)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```bash
feat: add tmux plugin manager support

Adds TPM installation and configuration for tmux.
Includes popular plugins for session management.

Closes #42
```

```bash
fix: correct homebrew prefix detection on apple silicon

The is-arm64 script was returning incorrect values on M1 Macs.
Updated to properly detect ARM architecture.
```

```bash
docs: update installation instructions for linux

Added Ubuntu-specific setup instructions and package lists.
```

## Coding Standards

### Shell Scripts

- Use `#!/usr/bin/env bash` shebang
- Add error handling with `set -euo pipefail` where appropriate
- Use lowercase for variables, UPPERCASE for constants
- Quote variables: `"$variable"`
- Use `[[` instead of `[` for conditionals
- Add comments for complex logic
- Run shellcheck before committing

**Example:**
```bash
#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

main() {
    local config_file="${1:-}"

    if [[ -z "$config_file" ]]; then
        echo "Error: Config file required" >&2
        return 1
    fi

    # Process configuration
    process_config "$config_file"
}

main "$@"
```

### Makefile

- Use tabs for indentation
- Add comments explaining targets
- Use `@echo` for user-facing messages
- Check for command existence before using
- Handle errors gracefully with `|| true` when appropriate

### Configuration Files

- Use clear, descriptive comments
- Group related settings together
- Document non-obvious choices
- Keep platform-specific settings clearly marked

### Documentation

- Use Markdown for all documentation
- Keep line length reasonable (~80-100 chars)
- Use clear headings and subheadings
- Include code examples where helpful
- Add table of contents for long documents

## Testing

### Before Submitting

1. **Test your changes locally**
   ```bash
   # Test symlink creation
   make link

   # Verify symlinks
   ls -la ~/.config/

   # Test unlinking
   make unlink
   ```

2. **Test on clean environment (if possible)**
   ```bash
   # Use a VM or Docker container
   # Test full installation
   make
   ```

3. **Run linters (if applicable)**
   ```bash
   # Shell scripts
   shellcheck bin/*
   shellcheck .config/*/scripts/*

   # Markdown
   markdownlint *.md
   ```

4. **Check for broken links**
   ```bash
   # In documentation files
   ```

### Platform Testing

- Test on your platform (macOS/Linux)
- Note if you couldn't test on other platforms
- Document platform-specific behavior

## Documentation

### Required Documentation

When adding new features:

1. **Configuration README**
   - Create `.config/[app-name]/README.md`
   - Explain what the configuration does
   - Document keybindings/shortcuts
   - Add troubleshooting section

2. **Update main README.md**
   - Add tool to appropriate section
   - Update structure diagram if needed
   - Add to installation instructions if required

3. **Update TODO.md**
   - Mark completed items
   - Add new discovered tasks
   - Update relevant sections

4. **Update CLAUDE.md** (if needed)
   - Add important context for AI assistants
   - Document new conventions
   - Add to Watch Out For section if there are gotchas

### Documentation Style

- Use clear, concise language
- Provide examples and code snippets
- Use bullet points for lists
- Add screenshots/demos where helpful (optional)
- Keep formatting consistent

## Pull Request Process

### Before Creating PR

1. **Update your fork**
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Ensure all changes are committed**
   ```bash
   git status
   ```

3. **Run final checks**
   - Test your changes
   - Run linters
   - Update documentation

### Creating the PR

1. **Push your branch**
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create Pull Request on GitHub**
   - Use a clear, descriptive title
   - Reference related issues (Closes #123)
   - Describe what changes were made
   - Explain why the changes are needed
   - Note any platform-specific considerations
   - Add screenshots if UI changes

3. **PR Template**
   ```markdown
   ## Description
   Brief description of changes

   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Documentation update
   - [ ] Refactoring

   ## Testing
   How the changes were tested

   ## Checklist
   - [ ] Code follows style guidelines
   - [ ] Documentation updated
   - [ ] TODO.md updated
   - [ ] Tested on clean environment
   - [ ] No breaking changes (or documented)

   ## Related Issues
   Closes #123
   ```

### After Creating PR

- Respond to review feedback promptly
- Make requested changes in new commits
- Keep PR focused and reasonably sized
- Be patient and respectful

### PR Review Criteria

Reviewers will check for:
- Code quality and style
- Documentation completeness
- Testing coverage
- No breaking changes (or properly documented)
- Follows project conventions

## Questions?

- Check existing issues and documentation
- Open a new issue for discussion
- Be specific about your question or problem

## Additional Resources

- [README.md](README.md) - Main documentation
- [CLAUDE.md](CLAUDE.md) - AI assistant guide
- [TODO.md](TODO.md) - Project roadmap
- [Dotfiles Guide](https://dotfiles.github.io/)
- [Conventional Commits](https://www.conventionalcommits.org/)

---

Thank you for contributing! 🎉
