# typed: strict
# frozen_string_literal: true

# Gbox is a self-hostable sandbox for MCP and AI agents
class Gbox < Formula
  desc "Self-hostable sandbox for MCP and AI agents"
  homepage "https://github.com/babelcloud/gru-sandbox"

  # Version definition
  GBOX_VERSION = "0.0.6"
  version ENV["HOMEBREW_GBOX_VERSION"] || GBOX_VERSION

  # Base URL for downloads
  base_url = "https://github.com/babelcloud/gru-sandbox/releases/download/v#{version}"
  url ENV["HOMEBREW_GBOX_URL"] || "#{base_url}/gbox-#{OS.mac? ? "darwin" : "linux"}-#{Hardware::CPU.arm? ? "arm64" : "amd64"}-#{version}.tar.gz"

  # SHA256 definitions for different architectures
  DARWIN_ARM64_SHA256 = "c6ba6122b02de8f4316d157c59284e9f7616c7ab03cc76792f5089e475f29860"
  DARWIN_AMD64_SHA256 = "5f91d7d3fa5ec2ae12577d68260f24631c1d543245c475ca7f4aa20fbe77389a"
  LINUX_ARM64_SHA256  = "b9642780fe1fb4c8b3c4339833a1a81038e736d90f205289fcd20698c25b0453"
  LINUX_AMD64_SHA256  = "bd3de2e3ba090aec7cb9e81338cb2b6d79b48bb2718cf1fdfcfd4945b9c2e0b3"

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
