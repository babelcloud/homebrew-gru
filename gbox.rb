# typed: strict
# frozen_string_literal: true

# Gbox is a self-hostable sandbox for MCP and AI agents
class Gbox < Formula
  desc "Self-hostable sandbox for MCP and AI agents"
  homepage "https://github.com/babelcloud/gru-sandbox"
  version = "0.0.1"
  url "https://github.com/babelcloud/gru-sandbox/releases/download/#{version}/gbox-#{version}.tar.gz"
  sha256 "23d21134ae2c3bcf7dc1a53bc79188de94db8033af52a832e823a225c8d1d3ff"

  def install
    # Install all contents to the Cellar directory
    prefix.install Dir["*"]
  end

  test do
    system "#{bin}/gbox", "--version"
  end
end
