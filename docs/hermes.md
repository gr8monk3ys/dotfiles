# Hermes Agent, offline

[Hermes Agent](https://github.com/NousResearch/hermes-agent) (NousResearch)
pointed at the local [Ollama](https://ollama.com) instead of a hosted API, the
same way on macOS and Arch/Omarchy. Nothing leaves the machine.

## Why it is not vendored

`~/.hermes/config.yaml` sits next to Hermes' sessions, memories, `.env` (API
keys) and caches, and Hermes migrates the file itself between versions. So it
is not tracked; [`bin/hermes-offline`](../bin/hermes-offline) sets only the
four keys below through `hermes config set` and leaves the rest alone.

| Key | Value | Why |
| --- | --- | --- |
| `model.provider` | `custom` | any OpenAI-compatible endpoint (`ollama` is an alias of it) |
| `model.base_url` | `http://127.0.0.1:11434/v1` | Ollama's OpenAI-compatible API |
| `model.default` | `gpt-oss:20b` | fits a 16GB+ GPU or an M-series Mac with 24GB+; override with `HERMES_MODEL` |
| `model.ollama_num_ctx` | `65536` | Hermes needs at least a 64K context; without this Ollama serves 2048 |

## Steps

1. **Ollama.** In `install/Brewfile` and `install/pacmanfile`, so `make`
   installs it. Start it:
   - macOS: `brew services start ollama`
   - Arch/Omarchy: `systemctl --user enable --now ollama` if your package
     ships the user unit, otherwise `ollama serve` in a terminal
2. **The model.** `ollama pull gpt-oss:20b` (about 13GB).
3. **Hermes and its config.**

   ```bash
   make hermes-offline              # dry run: what would change
   make hermes-offline apply=1      # install Hermes if missing, set the keys
   make hermes-offline apply=1 pull=1   # ...and pull the model if absent
   ```

   Installing runs Hermes' official installer
   (`curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash`),
   which puts `hermes` in `~/.local/bin`. Read it first if you prefer.
4. **Check.** `hermes config get model.default`, then run `hermes` with the
   network off.

## Gotchas

- 64K of context on a 20B model needs real memory: about 16GB of VRAM or
  unified memory beyond the weights' own. If Ollama falls back to the CPU,
  pick a smaller model (`HERMES_MODEL=qwen3:8b make hermes-offline apply=1`)
  rather than lowering the context: `HERMES_NUM_CTX` below 65536 is refused.
- `hermes update` can rewrite `config.yaml` (new options, a new
  `_config_version`); the four keys survive, and re-running
  `make hermes-offline` reports `ok` when they did.
