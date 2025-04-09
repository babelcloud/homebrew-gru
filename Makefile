.PHONY: help update-gbox

REPO := babelcloud/gru-sandbox
RELEASE_URL := https://github.com/$(REPO)/releases/download/v$(VERSION)
SHA256_CMD := curl -sfL $(RELEASE_URL)/gbox-$(VERSION).tar.gz.sha256 2>/dev/null | tr -s ' ' | cut -d ' ' -f 1 || \
	(echo "SHA256 file not found, calculating from tar.gz..." >&2 && \
	curl -sL $(RELEASE_URL)/gbox-$(VERSION).tar.gz | shasum -a 256 | cut -d ' ' -f 1)

.DEFAULT_GOAL := help

help: ## Show this help message
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' Makefile | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

update-gbox: check-version ## Update gbox.rb formula to specified version (usage: make update-gbox VERSION=x.x.x)
	@echo "Updating gbox.rb to version $(VERSION)"
	@# Verify release exists
	@gh release view v$(VERSION) --repo $(REPO) > /dev/null || (echo "Release v$(VERSION) not found"; exit 1)
	
	@# Update version and sha256 in gbox.rb
	@SHA256=$$($(SHA256_CMD)); \
	sed -i '' \
		-e 's/GBOX_VERSION = ".*"/GBOX_VERSION = "$(VERSION)"/' \
		-e 's/DARWIN_ARM64_SHA256 = ".*"/DARWIN_ARM64_SHA256 = "'$$SHA256'"/' \
		-e 's/DARWIN_AMD64_SHA256 = ".*"/DARWIN_AMD64_SHA256 = "'$$SHA256'"/' \
		-e 's/LINUX_ARM64_SHA256  = ".*"/LINUX_ARM64_SHA256  = "'$$SHA256'"/' \
		-e 's/LINUX_AMD64_SHA256  = ".*"/LINUX_AMD64_SHA256  = "'$$SHA256'"/' \
		gbox.rb
	
	@echo "Formula updated successfully!"

test-gbox: check-version ## Test gbox formula locally with specified version (usage: make test-gbox VERSION=x.x.x)
	@echo "Testing gbox.rb with version $(VERSION)"
	@# Detect system architecture
	@ARCH=$$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/'); \
	OS=$$(uname -s | tr '[:upper:]' '[:lower:]'); \
	TAR_PATH="$$(pwd)/../gru-sandbox/dist/gbox-$$OS-$$ARCH-$(VERSION).tar.gz"; \
	echo "Using local tar: $$TAR_PATH"; \
	if [ ! -f "$$TAR_PATH" ]; then \
		echo "Error: $$TAR_PATH does not exist"; \
		exit 1; \
	fi; \
	env HOMEBREW_GBOX_VERSION=$(VERSION) HOMEBREW_GBOX_URL="file://$$TAR_PATH" brew reinstall --build-from-source ./gbox.rb

check-version:
ifndef VERSION
	$(error VERSION is required. Usage: make update-gbox VERSION=x.x.x)
endif
