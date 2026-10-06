# latexmk

Build defaults for [latexmk](https://ctan.org/pkg/latexmk), which reruns
LaTeX, BibTeX and friends until a document settles. latexmk reads
`$XDG_CONFIG_HOME/latexmk/latexmkrc` itself; a `latexmkrc` in a project
directory overrides it.

## Why these choices

- **XeLaTeX** (`$pdf_mode = 5`): system fonts and UTF-8 input without
  `fontenc`/`inputenc` boilerplate.
- **Everything generated goes to `out/`** (`$out_dir`), so a document
  directory holds only sources. The PDF is in `out/` too.
- **`$bibtex_use = 1.5`:** run BibTeX only when the `.bib` files exist, and
  let `latexmk -c` delete the `.bbl` only then, so a `.bbl` shipped without
  its `.bib` (arXiv sources) survives a clean.
- **SyncTeX on**, and its files counted as generated so `latexmk -c` removes
  them. They let a viewer jump between source line and page
  (`zathura --synctex-forward`).
- **`$silent = 1`:** errors still print; the page of TeX chatter does not.

## Gotchas

- No manifest installs latexmk or a TeX distribution; this config waits for
  one (MacTeX, or `texlive` on Arch).
