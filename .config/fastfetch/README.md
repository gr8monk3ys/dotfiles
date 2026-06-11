# Fastfetch Configuration

System-info splash screen — the actively maintained successor to neofetch.

## Why fastfetch

- **Role:** On-demand system overview (OS, uptime, packages, CPU/GPU/memory)
  with the distro logo. Purely cosmetic, occasionally useful.
- **Why not neofetch:** unmaintained since 2024; fastfetch is a faster C
  rewrite with the same output style.
- **Not run on shell startup** — it would add noticeable latency to every
  new terminal. Use the `ff` alias (defined in
  [`.config/zsh/aliases.zsh`](../zsh/aliases.zsh)) when you want it.

## Configuration choices

- Key colors use blue/magenta to match the repo-wide OneDark accents.
- Module list is trimmed to the useful subset; the trailing `colors` block
  doubles as a terminal palette check.

## Upstream

- <https://github.com/fastfetch-cli/fastfetch>
