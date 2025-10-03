# lf (List Files) Configuration

This directory contains the configuration for [lf](https://github.com/gokcehan/lf), a terminal file manager written in Go.

## Files

- `lfrc` - Configuration file for lf file manager

## What is lf?

lf (list files) is a terminal-based file manager inspired by ranger, offering:
- Vim-like keybindings
- Fast performance (written in Go)
- Customizable through configuration and shell scripts
- Preview support for various file types
- Bulk operations on files
- Integration with external tools

## Configuration Overview

The `lfrc` file controls lf's behavior, appearance, and keybindings using a simple scripting language.

### Common Settings

#### General Options
```
set hidden true              # Show hidden files
set icons true              # Enable file icons
set ignorecase true         # Case-insensitive search
set preview true            # Enable file preview
set drawbox true            # Draw borders
```

#### UI Customization
- **Colors**: Terminal color scheme integration
- **Ratios**: Adjust pane width ratios
- **Info**: Display file information
- **Scrolloff**: Lines visible above/below cursor

#### Key Mappings
Custom keybindings for:
- Navigation
- File operations (copy, move, delete)
- Opening files with specific applications
- Running shell commands
- Creating files and directories

### Commands

lf supports custom commands written in shell:
```
cmd open ${{
    case $(file --mime-type "$f" -b) in
        text/*) $EDITOR "$f";;
        image/*) sxiv "$f";;
        video/*) mpv "$f";;
        *) xdg-open "$f";;
    esac
}}
```

## Usage

lf automatically loads configuration from:
- `~/.config/lf/lfrc` (primary location)
- `~/.lfrc` (fallback location)

### Basic Navigation

- `j/k` - Move down/up
- `h/l` - Go to parent/child directory
- `gg/G` - Go to top/bottom
- `/` - Search
- `space` - Select file
- `enter` - Open file

### File Operations

- `y` - Copy (yank)
- `d` - Cut
- `p` - Paste
- `<delete>` - Delete
- `:` - Enter command mode

## Integration

lf can integrate with:
- **Preview Scripts**: ueberzug, chafa for image preview
- **File Openers**: xdg-open, rifle for opening files
- **Archives**: atool for archive management
- **Editors**: Vim, Neovim, Emacs
- **Shell**: Execute shell commands on selected files

## File Previews

Common preview configurations:
- Text files: cat, bat, highlight
- Images: chafa, w3mimgdisplay, ueberzug
- PDFs: pdftotext
- Archives: tar, unzip listings
- Media: mediainfo, exiftool

## Resources

- [lf GitHub Repository](https://github.com/gokcehan/lf)
- [lf Documentation](https://pkg.go.dev/github.com/gokcehan/lf)
- [lf Wiki](https://github.com/gokcehan/lf/wiki)
- [Example Configs](https://github.com/gokcehan/lf/wiki/Ranger)
