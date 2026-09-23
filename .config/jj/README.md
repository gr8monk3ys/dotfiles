# jj

[Jujutsu](https://jj-vcs.github.io/jj/latest/), used beside git: most repos
here are colocated (`jj git init --colocate`), so jj and git read the same
`.git`. Git stays the fallback and the thing CI and GitHub see.

## Identity

The tracked `config.toml` carries no name or email. jj reads every `*.toml` in
`~/.config/jj/conf.d/` after `config.toml`, so identity lives there instead:

```toml
[user]
name = "Your Name"
email = "you@example.com"
```

`conf.d/` is gitignored apart from `user.toml.example`. Write the real file
with `make init`, which defaults jj's identity to the git identity you give it:

```bash
make init                                              # prompts
make init GIT_USER_NAME="Your Name" GIT_USER_EMAIL=you@example.com
make init check=1                                      # report only
```

Pass `JJ_USER_NAME` / `JJ_USER_EMAIL` on the machine where the two differ. An
existing `user.toml` is never rewritten.

## Why these choices

- **Bare `jj` shows the log** (`default-command`), and the log template is one
  line per change: change id, author, time, bookmarks, then the description
  or a visible "(no description set)".
- **Diffs look like git's:** `diff.format = "git"`, paged through `delta`
  (the same pager as `.config/git/`); the built-in diff and merge editors
  need nothing else installed.
- **Short aliases** mirroring the git habits they replace (`s`, `d`, `l`,
  `ll` for trunk to `@`, `gp`, `gf`, `u` for undo). The list is
  `[aliases]` in `config.toml`.
- **Colours are named ANSI colours**, so they follow the terminal's danse
  theme without a rendered region.

## Gotchas

- `color = "always"` keeps escape codes in piped output; pass
  `--color=never` when scripting.
- An alias that shadows a built-in command makes jj print a warning on every
  invocation. It has happened here once; after adding an alias, run `jj` and
  check it prints none.
