# typed: strict
# frozen_string_literal: true

# Gbox is a self-hostable sandbox for MCP and AI agents
class Gbox < Formula
  desc "Self-hostable sandbox for MCP and AI agents"
  homepage "https://github.com/babelcloud/gru-sandbox"
  version "0.0.3"
  url "https://github.com/babelcloud/gru-sandbox/releases/download/v#{version}/gbox-#{version}.tar.gz"
  sha256 "a3fd679ef51fbe1d379c5881a8dd4d50d714744b41ebe61dcea848e083ffdeff"

  depends_on "carvel-dev/carvel/ytt"
  depends_on "carvel-dev/carvel/kapp"
  depends_on "kind"
  depends_on "yq"
  depends_on "jq"

  def install
    prefix.install Dir["*"]
  end

  test do
    system "#{bin}/gbox", "--version"
  end
end
