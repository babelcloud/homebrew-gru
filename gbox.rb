# typed: strict
# frozen_string_literal: true

# Gbox is a self-hostable sandbox for MCP and AI agents
class Gbox < Formula
  desc "Self-hostable sandbox for MCP and AI agents"
  homepage "https://github.com/babelcloud/gru-sandbox"
  version "0.0.4"
  url "https://github.com/babelcloud/gru-sandbox/releases/download/v#{version}/gbox-#{version}.tar.gz"
  sha256 "0da7bee6424150dc57ebdb4d186bf8289ab38d1d257430b30c5e54219e4db3dd"

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
