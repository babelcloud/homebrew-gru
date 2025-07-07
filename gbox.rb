# typed: strict
# frozen_string_literal: true

# Gbox is a self-hostable sandbox for MCP and AI agents
class Gbox < Formula
  desc "Self-hostable sandbox for MCP and AI agents"
  homepage "https://github.com/babelcloud/gru-sandbox"

  # Version definition
  GBOX_VERSION = "0.0.14"
  version ENV["HOMEBREW_GBOX_VERSION"] || GBOX_VERSION

  # Base URL for downloads
  base_url = "https://github.com/babelcloud/gru-sandbox/releases/download/v#{version}"
  url ENV["HOMEBREW_GBOX_URL"] || "#{base_url}/gbox-#{OS.mac? ? "darwin" : "linux"}-#{Hardware::CPU.arm? ? "arm64" : "amd64"}-#{version}.tar.gz"

  # SHA256 definitions for different architectures
  DARWIN_ARM64_SHA256 = "9bc643517fb70b446b61d2754ec5cff5ab8ef66afd00ce0156645e43e6cfcffc"
  DARWIN_AMD64_SHA256 = "dd44bd71949b402a7060664bb4c6a2a83938debde9a8ec24a6986f4b656a74cd"
  LINUX_ARM64_SHA256  = "0cd05bd6c051d814d475ff0e86a9ab4f8cfc7b0f17b5be7016d876851642817a"
  LINUX_AMD64_SHA256  = "5380f8370bff8bb4825c8ec584d4093435198d5549b8f8e5e301c573bb40a4fb"

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
