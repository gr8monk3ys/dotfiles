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
