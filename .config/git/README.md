# Git Configuration

This directory contains the global configuration for [Git](https://git-scm.com/), the distributed version control system.

## Files

- `.gitconfig` - Global Git configuration file

## What is .gitconfig?

The `.gitconfig` file defines global settings for Git that apply to all repositories on your system. It allows you to customize:
- User identity (name and email)
- Default behaviors and preferences
- Command aliases
- Merge and diff tools
- Credential handling
- Color schemes

## Configuration Structure

The file is organized into sections:

### [user]
Defines your identity for commits:
```ini
[user]
    name = Your Name
    email = your.email@example.com
```

### [core]
Core Git settings like default editor, line endings, and exclusions

### [alias]
Custom shortcuts for Git commands, making complex operations simpler

### [color]
Color output settings for better readability in terminal

### [merge] / [diff]
Configure merge strategies and diff tools

### [push] / [pull]
Default behaviors for push and pull operations

## Usage

Git automatically reads this file from `~/.gitconfig` (or `$XDG_CONFIG_HOME/git/.gitconfig`). Settings here apply globally unless overridden by repository-specific configurations.

### Viewing Configuration

```bash
# View all settings
git config --global --list

# View specific setting
git config --global user.name
```

### Modifying Configuration

You can edit the file directly or use Git commands:

```bash
# Set a value
git config --global user.email "new.email@example.com"

# Add an alias
git config --global alias.st status
```

## Common Aliases

Typical aliases include:
- `st` → `status`
- `co` → `checkout`
- `br` → `branch`
- `ci` → `commit`
- `unstage` → `reset HEAD --`
- `last` → `log -1 HEAD`

## Best Practices

1. Keep sensitive information (like tokens) out of `.gitconfig`
2. Use aliases for frequently used commands
3. Configure a global `.gitignore` for system-specific files
4. Set up GPG signing for commits if needed
5. Configure credential helpers for HTTPS authentication

## Resources

- [Git Configuration Documentation](https://git-scm.com/docs/git-config)
- [Git Book - Configuration](https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration)
- [GitHub Git Configuration Guide](https://docs.github.com/en/get-started/getting-started-with-git/setting-your-username-in-git)
