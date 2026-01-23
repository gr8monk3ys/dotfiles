# Bin Directory

Utility scripts used by the Makefile and for general system management.

## Helper Scripts (Makefile Dependencies)

These scripts are used by the Makefile to detect system configuration:

### [is-supported](is-supported)
Checks if a command is supported (executable exists).

**Usage:**
```bash
is-supported <command> <return-if-true> <return-if-false>
```

**Example:**
```bash
is-supported brew /opt/homebrew /usr/local
```

### [is-macos](is-macos)
Checks if running on macOS.

**Returns:** Exit code 0 if on macOS, 1 otherwise

**Usage:**
```bash
if is-macos; then
    echo "Running on macOS"
fi
```

### [is-arch](is-arch)
Checks if running on Arch Linux.

**Returns:** Exit code 0 if on Arch Linux, 1 otherwise

**Usage:**
```bash
if is-arch; then
    echo "Running on Arch Linux"
fi
```

### [is-arm64](is-arm64)
Checks if running on ARM64 architecture (Apple Silicon).

**Returns:** Exit code 0 if ARM64, 1 otherwise

**Usage:**
```bash
if is-arm64; then
    echo "Running on Apple Silicon"
    HOMEBREW_PREFIX="/opt/homebrew"
else
    echo "Running on Intel"
    HOMEBREW_PREFIX="/usr/local"
fi
```

### [is-executable](is-executable)
Checks if a command is executable (available in PATH).

**Usage:**
```bash
if is-executable brew; then
    echo "Homebrew is installed"
fi
```

## Utility Scripts

### [dotfiles-doctor](dotfiles-doctor)
Comprehensive health check for your dotfiles installation.

**Usage:**
```bash
dotfiles-doctor
# or
make doctor
```

### [dotfiles-update](dotfiles-update)
Update all packages and configurations.

**Usage:**
```bash
dotfiles-update [--skip-brew] [--skip-npm] [--skip-cargo]
# or
make update
```

### [dotfiles-backup](dotfiles-backup)
Backup configurations and package lists.

**Usage:**
```bash
dotfiles-backup [--compress] [--cleanup]
# or
make backup
```

### [dotfiles-template](dotfiles-template)
Template processor for machine-specific configurations.

**Usage:**
```bash
# List available variables
dotfiles-template --list

# Process a template
dotfiles-template config.tmpl config

# Dry run
dotfiles-template --dry-run config.tmpl
```

**Available Variables:**
- `{{HOSTNAME}}` - System hostname
- `{{OS_TYPE}}` - OS type (macos, arch, linux)
- `{{MACHINE_TYPE}}` - Machine profile (personal, work, server)
- `{{USER}}` - Current username
- `{{HOME}}` - Home directory

**Conditional Blocks:**
```
{{#if MACHINE_TYPE eq work}}
# Work-specific configuration
{{/if}}
```

### [dotfiles-secrets](dotfiles-secrets)
Secret management using age encryption.

**Usage:**
```bash
# Initialize encryption key
dotfiles-secrets init

# Encrypt a file
dotfiles-secrets encrypt ~/.ssh/config

# Decrypt a file
dotfiles-secrets decrypt secrets/config.age

# Edit an encrypted file
dotfiles-secrets edit secrets/config.age

# Show status
dotfiles-secrets status
```

**Requirements:** Install `age` with `brew install age` or `pacman -S age`.

## Scripts from .local/bin

Additional utility scripts are located in `.local/bin/`. These include 20 scripts for:

- **System Configuration**: `macos-defaults`
- **Security**: `yubikey-ssh-setup`, `setup-tor-iptables`, `tor-exit-threat-score`
- **Development**: `check-go-repos`, `generate-go-project-files`, `generate-md-toc`, `openprs`
- **Repository Management**: `update-repos`
- **Docker**: `cleanup-non-running-images`
- **Display/Hardware**: `monitor-hotplug`, `screen-backlight`, `fancy-i3lock`
- **Firmware**: `update-firmware`, `update-iwlwifi`
- **Other**: `browser-exec`, `check-kconfig`, `createvm`, `slackpm`, `install.sh`

**See [.local/bin/README.md](../.local/bin/README.md) for comprehensive documentation** including usage examples, platform compatibility, and dependencies.

## Making Scripts Executable

On Unix-like systems (macOS/Linux), ensure scripts are executable:

```bash
chmod +x bin/*
chmod +x .local/bin/*
```

Git will preserve the executable bit when files are committed and cloned.

## Adding New Scripts

When adding new scripts:

1. Create the script in the appropriate directory
2. Add a shebang line (e.g., `#!/usr/bin/env bash`)
3. Make it executable: `chmod +x script-name`
4. Document it in this README
5. Test on target platforms

## Platform Compatibility

- **Helper scripts (is-*)**: macOS and Linux
- **.local/bin scripts**: Varies by script, check individual documentation
- **Windows**: Most scripts require WSL or Git Bash

## Resources

- [Bash Scripting Guide](https://www.gnu.org/software/bash/manual/)
- [Shell Check](https://www.shellcheck.net/) - Script linting
- [Makefile Documentation](../Makefile)
