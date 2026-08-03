# frozen_string_literal: true

# Homebrew formula for comma-cli — binary distribution from GitHub releases.
# Update `version`, the four urls and sha256s on each upstream release
# (hashes are published in the release's sha256sums.txt).
class CommaCli < Formula
  desc "Turn natural-language intent into a shell command using an LLM"
  homepage "https://github.com/miuzel/comma-cli"
  version "0.22.0"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/miuzel/comma-cli/releases/download/v0.22.0/comma-macos-aarch64.tar.gz"
      sha256 "c4bf194157bcb2bbd73cf502581d05c54107d6b6f95376c4df27c03b3c6b07a8"
    end
    on_intel do
      url "https://github.com/miuzel/comma-cli/releases/download/v0.22.0/comma-macos-x86_64.tar.gz"
      sha256 "033a518795f2acaf7152c77ef510202f0d6c42a342906dfaaece75a3b45eeb97"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/miuzel/comma-cli/releases/download/v0.22.0/comma-linux-x86_64.tar.gz"
      sha256 "f22afe908d3c19812b05f528e8d582faa2352aa0ea63ca1d01559d8255f4bfa6"
    end
    on_arm do
      url "https://github.com/miuzel/comma-cli/releases/download/v0.22.0/comma-linux-aarch64.tar.gz"
      sha256 "be21be1a4a8224db172fd5b6a9a14b08881589f7404c74a9881d7295d923e505"
    end
  end

  def install
    # The upstream binary is invoked as `,`; `comma` is provided as an alias.
    bin.install "comma" => ","
    ln_sf ",", bin/"comma"

    # Interactive first-time setup helper. Homebrew points HOME at a
    # temporary build dir during install/post_install (and user lookups are
    # unreliable there), so config prompting cannot live in post_install —
    # it ships as a regular command run in the user's real environment.
    (buildpath/"comma-setup").write <<~'SH'
      #!/bin/sh
      # comma-setup: interactive first-time setup for comma-cli.
      # Writes $XDG_CONFIG_HOME/comma/config.json (default ~/.config/comma/config.json).
      set -eu

      config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/comma"
      config_file="$config_dir/config.json"

      if [ -f "$config_file" ]; then
        echo "Config already exists: $config_file"
        exit 0
      fi

      # Escape \ and " for embedding in a JSON string.
      esc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

      printf 'Base URL (e.g. https://api.cerebras.ai/v1) [skip]: '
      read -r base_url || base_url=""
      api_key=""
      model=""
      if [ -n "$base_url" ]; then
        printf 'API key: '
        read -r api_key || api_key=""
        if [ -n "$api_key" ]; then
          printf 'Model name (e.g. gemma-4-31b): '
          read -r model || model=""
        fi
      fi

      # Skipping any step still leaves a config file (with whatever was
      # entered) for the user to edit later.
      mkdir -p "$config_dir"
      {
        printf '{\n'
        printf '  "base_url": "%s",\n' "$(esc "$base_url")"
        printf '  "auth_token": "%s",\n' "$(esc "$api_key")"
        printf '  "model": "%s",\n' "$(esc "$model")"
        printf '  "cache_size": 1000,\n'
        printf '  "reasoning": 0\n'
        printf '}\n'
      } > "$config_file"
      chmod 600 "$config_file"
      if [ -n "$base_url" ] && [ -n "$api_key" ] && [ -n "$model" ]; then
        echo "Config written to $config_file"
      else
        echo "Default config written to $config_file — edit it to add your API key/model."
      fi
    SH
    (buildpath/"comma-setup").chmod 0o755
    bin.install "comma-setup"
  end

  def caveats
    <<~EOS
      Usage: , <what you want to do>
        , find all TODO comments in python files
      (`comma` is an alias if your shell dislikes `,`)

      First-time setup (interactively creates ~/.config/comma/config.json):
        comma-setup
      Or set the COMMA_BASE_URL, COMMA_API_KEY and COMMA_MODEL environment variables.
      Free model providers: Cerebras (cerebras.ai), Groq (groq.com), Ollama (local).

      Optional shell integration (lets generated `cd`/env changes apply to your shell):
        https://github.com/miuzel/comma-cli#shell-integration
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/, --version")
    assert_path_exists bin/"comma"
  end
end
