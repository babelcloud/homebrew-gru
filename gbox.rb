# typed: strict
# frozen_string_literal: true

# Gbox is a self-hostable sandbox for MCP and AI agents
class Gbox < Formula
  desc "Self-hostable sandbox for MCP and AI agents"
  homepage "https://github.com/babelcloud/gru-sandbox"

  # Version definition
  GBOX_VERSION = "0.0.10"
  version ENV["HOMEBREW_GBOX_VERSION"] || GBOX_VERSION

  # Base URL for downloads
  base_url = "https://github.com/babelcloud/gru-sandbox/releases/download/v#{version}"
  url ENV["HOMEBREW_GBOX_URL"] || "#{base_url}/gbox-#{OS.mac? ? "darwin" : "linux"}-#{Hardware::CPU.arm? ? "arm64" : "amd64"}-#{version}.tar.gz"

  # SHA256 definitions for different architectures
  DARWIN_ARM64_SHA256 = "8bdc1ce824268d8a6516f1acebab2200d81e9464d0b4fd956533f8baaad3657b"
  DARWIN_AMD64_SHA256 = "448d653cb5a9beca9c4a6456747503327a59dfc247a4cd8e949578f87b1af2e6"
  LINUX_ARM64_SHA256  = "ca5ef0808d85c27f6231324095855b9829e77494900b5d1ecdb1ff20a3b11154"
  LINUX_AMD64_SHA256  = "d893a6d89f98c1bed7b082b3f9726643cfff1238c553a862b9d2aaf0032d10d3"

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

  def install
    prefix.install Dir["*"]
  end

  test do
    system "#{bin}/gbox", "--version"
  end
end
