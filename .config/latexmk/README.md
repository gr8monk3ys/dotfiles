# Latexmk Configuration

This directory contains the configuration for [Latexmk](https://www.cantab.net/users/johncollins/latexmk/), a Perl script for automating LaTeX document compilation.

## Files

- `latexmkrc` - Configuration file for Latexmk automation

## What is Latexmk?

Latexmk is a build automation tool for LaTeX documents that:
- Automatically runs LaTeX the correct number of times
- Handles bibliography generation (BibTeX/Biber)
- Manages index generation
- Runs auxiliary tools as needed
- Provides continuous preview mode
- Cleans up auxiliary files

## Configuration Overview

The `latexmkrc` file uses Perl syntax to configure Latexmk's behavior.

### Common Settings

Typical configurations include:

#### Output Format
```perl
$pdf_mode = 1;          # Generate PDF via pdflatex
$pdf_mode = 4;          # Generate PDF via lualatex
$pdf_mode = 5;          # Generate PDF via xelatex
```

#### PDF Viewer
```perl
$pdf_previewer = 'open';              # macOS
$pdf_previewer = 'zathura';           # Linux
$pdf_previewer = 'start';             # Windows
```

#### Continuous Preview
```perl
$preview_continuous_mode = 1;  # Enable auto-recompilation
```

#### Build Directory
```perl
$out_dir = 'build';            # Output directory for auxiliary files
```

#### Custom Commands
- Define custom compilation sequences
- Set environment variables
- Configure tool-specific options

## Usage

Latexmk reads configuration from multiple locations in order:
1. System-wide: `/etc/latexmkrc` or similar
2. User-level: `~/.config/latexmk/latexmkrc` or `~/.latexmkrc`
3. Project-level: `./latexmkrc` in the document directory

### Basic Commands

```bash
# Compile document
latexmk document.tex

# Continuous preview mode (auto-recompile on changes)
latexmk -pvc document.tex

# Clean auxiliary files
latexmk -c document.tex

# Clean all generated files (including PDF)
latexmk -C document.tex
```

## Benefits

1. **Automation**: No need to manually run LaTeX multiple times
2. **Dependency Tracking**: Automatically detects when to rebuild
3. **Continuous Preview**: Live document updates while editing
4. **Cleanup**: Easy removal of auxiliary files
5. **Flexibility**: Supports multiple LaTeX engines and workflows

## Integration

Latexmk integrates well with:
- **Text Editors**: Vim, Emacs, VS Code (with LaTeX Workshop)
- **Build Systems**: Make, custom scripts
- **PDF Viewers**: Zathura, Skim, Okular for forward/inverse search

## Resources

- [Latexmk Documentation](https://www.cantab.net/users/johncollins/latexmk/)
- [Latexmk Manual](https://ctan.org/pkg/latexmk)
- [LaTeX Project](https://www.latex-project.org/)
