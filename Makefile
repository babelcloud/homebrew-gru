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
		-e 's/version ".*"/version "$(VERSION)"/' \
		-e 's/sha256 ".*"/sha256 "'$$SHA256'"/' \
		gbox.rb
	
	@echo "Formula updated successfully!"

check-version:
ifndef VERSION
	$(error VERSION is required. Usage: make update-gbox VERSION=x.x.x)
endif
