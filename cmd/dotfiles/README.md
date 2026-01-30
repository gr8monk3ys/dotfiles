# Dotfiles CLI

A beautiful, interactive CLI for installing and managing Lorenzo's dotfiles.

## Features

- **Interactive Mode** - Beautiful TUI for selecting installation options
- **Multiple Installation Methods**
  - Traditional (Homebrew-based)
  - Nix (100% reproducible)
  - Minimal (symlinks only)
- **Machine Profiles** - Configure for personal, work, or server use
- **Cross-Platform** - Works on macOS and Linux
- **OneDark Theme** - Consistent styling with the dotfiles

## Installation

### Build from Source

```bash
cd cmd/dotfiles
go build -o dotfiles-cli .
./dotfiles-cli
```

### Install Globally

```bash
go install github.com/gr8monk3ys/dotfiles/cmd/dotfiles@latest
```

## Usage

### Interactive Mode (Recommended)

Simply run the CLI without arguments for an interactive experience:

```bash
./dotfiles-cli
```

This will guide you through:
1. Selecting an installation method
2. Choosing a machine profile
3. Running the installation

### Non-Interactive Mode

For scripting or CI/CD:

```bash
# Traditional installation
./dotfiles-cli install --method traditional --type personal

# Nix installation
./dotfiles-cli install --method nix --type personal

# Minimal (symlinks only)
./dotfiles-cli install --method minimal
```

### Available Commands

| Command | Description |
|---------|-------------|
| `dotfiles-cli` | Interactive installation wizard |
| `dotfiles-cli install` | Install with specified options |
| `dotfiles-cli doctor` | Run health check |
| `dotfiles-cli update` | Update dotfiles and packages |
| `dotfiles-cli link` | Create symlinks |
| `dotfiles-cli unlink` | Remove symlinks |

### Flags

#### Global Flags

| Flag | Short | Description |
|------|-------|-------------|
| `--dir` | `-d` | Dotfiles directory (default: ~/.dotfiles) |
| `--verbose` | `-v` | Verbose output |
| `--no-color` | | Disable color output |
| `--dry-run` | | Show what would be done |

#### Install Flags

| Flag | Short | Description |
|------|-------|-------------|
| `--method` | `-m` | Installation method: traditional, nix, minimal |
| `--type` | `-t` | Machine type: personal, work, server |
| `--skip-brew` | | Skip Homebrew packages |
| `--skip-casks` | | Skip Homebrew casks |
| `--skip-npm` | | Skip npm packages |
| `--skip-rust` | | Skip Rust/cargo packages |

## Examples

### Dry Run

See what would happen without making changes:

```bash
./dotfiles-cli install --method nix --dry-run
```

### Work Machine Setup

```bash
./dotfiles-cli install --method traditional --type work
```

### Server Setup (Minimal)

```bash
./dotfiles-cli install --method minimal --type server
```

### Custom Directory

```bash
./dotfiles-cli --dir ~/my-dotfiles install
```

## Development

### Build

```bash
go build -v -o dotfiles-cli .
```

### Test

```bash
go test ./...
```

### Dependencies

- [Cobra](https://github.com/spf13/cobra) - CLI framework
- [Bubble Tea](https://github.com/charmbracelet/bubbletea) - TUI framework
- [Lip Gloss](https://github.com/charmbracelet/lipgloss) - Terminal styling
- [Bubbles](https://github.com/charmbracelet/bubbles) - TUI components

## Architecture

```
cmd/dotfiles/
├── main.go       # CLI implementation
├── go.mod        # Go module definition
├── go.sum        # Dependency checksums
└── README.md     # This file
```

The CLI is designed to:
1. Detect the system (macOS/Linux, architecture)
2. Present installation options via TUI
3. Execute the appropriate Makefile targets
4. Provide beautiful, informative output
