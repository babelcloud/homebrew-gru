# typed: strict
# frozen_string_literal: true

# Gbox is a self-hostable sandbox for MCP and AI agents
# Note: This formula requires android-platform-tools cask to be installed.
# Install it with: brew install --cask android-platform-tools
class Gbox < Formula
  desc "Self-hostable sandbox for MCP and AI agents"
  homepage "https://github.com/babelcloud/gru-sandbox"

  # Version definition
  GBOX_VERSION = "0.1.10"
  version ENV["HOMEBREW_GBOX_VERSION"] || GBOX_VERSION

  # Base URL for downloads
  base_url = "https://github.com/babelcloud/gru-sandbox/releases/download/v#{version}"
  url ENV["HOMEBREW_GBOX_URL"] || "#{base_url}/gbox-#{OS.mac? ? "darwin" : "linux"}-#{Hardware::CPU.arm? ? "arm64" : "amd64"}-#{version}.tar.gz"

  # SHA256 definitions for different architectures
  DARWIN_ARM64_SHA256 = "68d9a7840d4719754599738f154f9261c35084b51e50408a08c483dcc77df71a"
  DARWIN_AMD64_SHA256 = "1c85fdfecb65c419fcb4ae0e786a462ff48eccaf752aa94bcb5b21dc9579cba1"
  LINUX_ARM64_SHA256  = "77175d2a5ecbc4080eff8261cf95fd2ae054373fa9b571dc1b95b51d882eb0ec"
  LINUX_AMD64_SHA256  = "d0e164f560bd55e93046dae6122e40ca6ed2dcd86912c4049999760a6a57757b"

  def self.get_sha256(url)
    return default_sha256 unless ENV["HOMEBREW_GBOX_URL"]

    sha256_url = url.sub(%r{^file://}, "") + ".sha256"

    content = if sha256_url.start_with?("https://")
      Utils::Curl.curl_output("--location", "--silent", sha256_url).stdout
    else
      File.read(sha256_url)
    end
    content.strip.split(/\s+/).first
  rescue
    default_sha256
  end

  def self.default_sha256
    if OS.mac?
      if Hardware::CPU.arm?
        DARWIN_ARM64_SHA256
      else
        DARWIN_AMD64_SHA256
      end
    else
      if Hardware::CPU.arm?
        LINUX_ARM64_SHA256
      else
        LINUX_AMD64_SHA256
      end
    end
  end

  sha256 get_sha256(url)

  depends_on "carvel-dev/carvel/ytt"
  depends_on "carvel-dev/carvel/kapp"
  depends_on "kind"
  depends_on "yq"
  depends_on "jq"
  depends_on "node"
  depends_on "frpc"

  def cask_installed?(cask_name)
    # Check if cask is installed by running brew list and checking exit code
    result = system("brew", "list", "--cask", cask_name)
    return result
  end

  def install
    prefix.install Dir["*"]
  end

  def caveats
    <<~EOS
      This formula requires android-platform-tools cask to be installed.
      If you haven't installed it yet, run:
        brew install --cask android-platform-tools
    EOS
  end

  test do
    system "#{bin}/gbox", "--version"
  end
end
