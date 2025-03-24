# typed: strict
# frozen_string_literal: true

# Gbox is a self-hostable sandbox for MCP and AI agents
class Gbox < Formula
  desc "Self-hostable sandbox for MCP and AI agents"
  homepage "https://github.com/babelcloud/gru-sandbox"
  version = "0.0.2"
  url "https://github.com/babelcloud/gru-sandbox/releases/download/#{version}/gbox-#{version}.tar.gz"
  sha256 "633aaf6d43266f5b4b1bbec59dbffd3cabfcca7f9174c31d9e14c633a6a20c86"

  depends_on "carvel-dev/carvel/ytt"
  depends_on "carvel-dev/carvel/kapp"
  depends_on "kind"
  depends_on "yq"
  depends_on "jq"

  def install
    # Install all contents to the Cellar directory
    prefix.install Dir["*"]
  end

  test do
    system "#{bin}/gbox", "--version"
  end
end
