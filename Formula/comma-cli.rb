# frozen_string_literal: true

# Homebrew formula for comma-cli — binary distribution from GitHub releases.
# Update `version`, the four urls and sha256s on each upstream release
# (hashes are published in the release's sha256sums.txt).
class CommaCli < Formula
  desc "Turn natural-language intent into a shell command using an LLM"
  homepage "https://github.com/miuzel/comma-cli"
  version "0.21.0"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/miuzel/comma-cli/releases/download/v0.21.0/comma-macos-aarch64.tar.gz"
      sha256 "db20bf8c10bf8915640caeb6709016b680810db7f6ffa41e2bea634109fea35d"
    end
    on_intel do
      url "https://github.com/miuzel/comma-cli/releases/download/v0.21.0/comma-macos-x86_64.tar.gz"
      sha256 "36dd03eef9906a967656af484725946eb21d60e53c123b1e2adb446ddfc8d27c"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/miuzel/comma-cli/releases/download/v0.21.0/comma-linux-x86_64.tar.gz"
      sha256 "37e0e1d12e1e1b1629265f8a02902dba58cc150f0dd20c8bd032b497329fe45a"
    end
    on_arm do
      url "https://github.com/miuzel/comma-cli/releases/download/v0.21.0/comma-linux-aarch64.tar.gz"
      sha256 "8028d828cacae6d96b671f28e9648f02cacb5f453346fb754a850c865bb2224b"
    end
  end

  def install
    # The upstream binary is invoked as `,`; `comma` is provided as an alias.
    bin.install "comma" => ","
    ln_sf ",", bin/"comma"
  end

  def post_install
    # Respect an existing config from a previous install (XDG or legacy).
    return if config_file.exist? || legacy_config_file.exist?

    # Never write the config into a temporary build dir — during install brew
    # points HOME there, and a wrong home resolution must not go unnoticed.
    tmp = ENV["HOMEBREW_TEMP"].to_s
    if config_dir.to_s.start_with?("/tmp/", "/private/tmp/", tmp.empty? ? "\0" : "#{tmp}/")
      opoo "Refusing to write config into a temporary dir: #{config_dir}"
      opoo "Create #{real_home}/.config/comma/config.json manually instead."
      return
    end

    # Prompt for model credentials only when a terminal is attached; the
    # prompt is skippable (Enter) and skipped entirely without a TTY.
    tty = begin
      File.open("/dev/tty", "r")
    rescue SystemCallError
      nil
    end
    if tty.nil?
      opoo "No config found; create #{config_file} (see `brew info comma-cli` for the format)"
      return
    end

    ohai "comma-cli first-time setup (press Enter to skip)"
    puts "No config found at #{config_file}."
    puts "Enter your model API details now, or skip and edit the file later."

    base_url = nil
    api_key = nil
    model = nil
    begin
      $stdout.print "Base URL (e.g. https://api.cerebras.ai/v1) [skip]: "
      base_url = tty.gets.to_s.strip
      return if base_url.empty?

      $stdout.print "API key: "
      api_key = tty.gets.to_s.strip
      return if api_key.empty?

      $stdout.print "Model name (e.g. gemma-4-31b): "
      model = tty.gets.to_s.strip
      return if model.empty?
    ensure
      tty.close
    end

    require "json"
    config_dir.mkpath
    config_file.write JSON.pretty_generate(
      "base_url" => base_url,
      "auth_token" => api_key,
      "model" => model,
      "cache_size" => 1000,
      "reasoning" => 0,
    )
    config_file.chmod 0o600
    ohai "Config written to #{config_file}"
  end

  def caveats
    <<~EOS
      Usage: , <what you want to do>
        , find all TODO comments in python files
      (`comma` is an alias if your shell dislikes `,`)

      Config file: #{config_file}
        Set base_url / auth_token / model there, or use the COMMA_BASE_URL,
        COMMA_API_KEY and COMMA_MODEL environment variables.
      Free model providers: Cerebras (cerebras.ai), Groq (groq.com), Ollama (local).

      Optional shell integration (lets generated `cd`/env changes apply to your shell):
        https://github.com/miuzel/comma-cli#shell-integration
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/, --version")
    assert_path_exists bin/"comma"
  end

  private

  def config_dir
    xdg = ENV["XDG_CONFIG_HOME"]
    base = xdg.nil? || xdg.empty? ? real_home/".config" : Pathname.new(xdg)
    base/"comma"
  end

  def config_file
    config_dir/"config.json"
  end

  def legacy_config_file
    real_home/".local/bin/,.config.json"
  end

  # Homebrew points HOME at a temporary build dir during install/post_install,
  # so Dir.home is wrong there — resolve the invoking user's home from the
  # passwd entry instead.
  def real_home
    require "etc"
    Pathname.new(Etc.getpwuid.dir)
  rescue StandardError
    Pathname.new(Dir.home)
  end
end
