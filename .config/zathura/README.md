# Zathura Configuration

This directory contains the configuration for [Zathura](https://pwmt.org/projects/zathura/), a highly customizable document viewer.

## Files

- `zathurarc` - Configuration file for Zathura

## What is Zathura?

Zathura is a lightweight, keyboard-driven document viewer that supports:
- PDF, PS, DjVu, and other document formats
- Vim-like keybindings
- Customizable appearance
- SyncTeX support for LaTeX integration
- Fast rendering
- Minimal memory footprint

## Configuration Overview

The `zathurarc` file customizes Zathura's behavior, appearance, and keybindings.

### Common Settings

#### Appearance
```
set default-bg "#1e1e1e"
set default-fg "#d4d4d4"
set statusbar-bg "#1e1e1e"
set statusbar-fg "#d4d4d4"
set recolor true
set recolor-lightcolor "#1e1e1e"
set recolor-darkcolor "#d4d4d4"
```

#### Behavior
```
set selection-clipboard clipboard
set adjust-open width
set pages-per-row 1
set scroll-page-aware true
set smooth-scroll true
set window-title-basename true
```

#### Key Mappings
```
map <C-i> zoom in
map <C-o> zoom out
map r reload
map R rotate
map p print
map i recolor
map J zoom out
map K zoom in
```

#### Search
```
set incremental-search true
set search-hadjust true
```

## Usage

Open documents with:
```bash
zathura document.pdf
zathura --mode fullscreen document.pdf
zathura --page 10 document.pdf
```

### Basic Navigation

- `j/k` - Scroll down/up
- `h/l` - Scroll left/right
- `J/K` - Page down/up (or zoom out/in if mapped)
- `gg/G` - Go to first/last page
- `H/L` - Go to top/bottom of page
- `<num>gg` - Go to page <num>
- `Space/Backspace` - Next/previous page

### Zoom and Display

- `+/-` - Zoom in/out
- `=` - Reset zoom
- `a` - Adjust to page width
- `s` - Adjust to page height
- `r` - Rotate page
- `R` - Recolor (invert colors)

### Search and Navigation

- `/` - Search forward
- `?` - Search backward
- `n` - Next search result
- `N` - Previous search result

### Other Commands

- `f` - Follow links (shows link hints)
- `F` - Display index (table of contents)
- `:` - Command mode
- `Tab` - Show index sidebar
- `d` - Toggle dual-page view
- `q` - Quit

## Features

### SyncTeX Support

For LaTeX integration:
```bash
# Forward search (from editor to PDF)
zathura --synctex-forward=line:column:file.tex file.pdf

# Inverse search (from PDF to editor)
# Configure in zathurarc:
set synctex true
set synctex-editor-command "vim --remote +%{line} %{input}"
```

### Color Schemes

Easily create color schemes for day/night reading:

**Dark Theme**
```
set recolor true
set recolor-lightcolor "#000000"
set recolor-darkcolor "#E0E0E0"
```

**Light Theme**
```
set recolor false
```

### Clipboard Integration

```
set selection-clipboard clipboard
```
Now selections automatically copy to clipboard.

## Integration

### LaTeX Editors

Integrate with Vim/Neovim using vimtex:
```vim
let g:vimtex_view_method = 'zathura'
```

### File Managers

Open PDFs from lf, ranger, or other file managers:
```bash
# In file manager config
map o $zathura "$f"
```

## Command Mode

Enter command mode with `:` for advanced features:
- `:set` - Change settings
- `:print` - Print document
- `:info` - Show document information
- `:exec` - Execute command
- `:open` - Open file

## Tips

1. **Recolor**: Press `Ctrl+R` to toggle recolor for better reading
2. **Fullscreen**: Press `F11` or start with `--mode fullscreen`
3. **Bookmarks**: Use `:bmark <name>` and `:blist` to manage bookmarks
4. **Multiple Windows**: Open same document in multiple windows for cross-referencing
5. **Export Images**: Right-click on images to save them

## Resources

- [Zathura Documentation](https://pwmt.org/projects/zathura/documentation/)
- [Zathura Manual](https://manpages.org/zathura)
- [Zathura Configuration](https://pwmt.org/projects/zathura/configuration/)
- [GitHub Repository](https://github.com/pwmt/zathura)
