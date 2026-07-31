# miuzel/homebrew-tap

Homebrew tap for [comma-cli](https://github.com/miuzel/comma-cli) — the tiny CLI that turns natural-language intent into a single shell command using an LLM.

## Install

```bash
brew install miuzel/tap/comma-cli
```

This installs the binary as `,` (with `comma` as an alias). If no config exists yet, the installer offers to prompt for your model API base URL, key and model name — press Enter to skip and edit `~/.config/comma/config.json` later. Without a terminal the prompt is skipped automatically.

## Upgrade

```bash
brew upgrade comma-cli
```

## Formula maintenance

`Formula/comma-cli.rb` tracks upstream releases: on each new comma-cli release, bump `version`, update the four archive URLs, and take the new hashes from the release's `sha256sums.txt`.
