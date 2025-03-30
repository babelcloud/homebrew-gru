# typed: strict
# frozen_string_literal: true

# Gbox is a self-hostable sandbox for MCP and AI agents
class Gbox < Formula
  desc "Self-hostable sandbox for MCP and AI agents"
  homepage "https://github.com/babelcloud/gru-sandbox"
  version "0.0.5"
  url "https://github.com/babelcloud/gru-sandbox/releases/download/v#{version}/gbox-#{version}.tar.gz"
  sha256 "6e2583056207f51af764a861d6a9f078b31db5246b1f2aae368a25158a8133c3"

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
