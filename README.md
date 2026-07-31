# miuzel/homebrew-tap

Homebrew tap for [comma-cli](https://github.com/miuzel/comma-cli) — the tiny CLI that turns natural-language intent into a single shell command using an LLM.

## Install

```bash
brew install miuzel/tap/comma-cli
```

This installs the binary as `,` (with `comma` as an alias) plus a `comma-setup` helper. Run `comma-setup` once to create `~/.config/comma/config.json` interactively (base URL, API key, model name) — or edit the file manually / use the `COMMA_BASE_URL`, `COMMA_API_KEY`, `COMMA_MODEL` env vars.

(Setup can't run inside `brew install` itself: Homebrew points `$HOME` at a temporary build dir during install hooks, so the prompt lives in `comma-setup`, which runs in your real environment.)

## Upgrade

```bash
brew upgrade comma-cli
```

## Formula maintenance

`Formula/comma-cli.rb` tracks upstream releases: on each new comma-cli release, bump `version`, update the four archive URLs, and take the new hashes from the release's `sha256sums.txt`.
