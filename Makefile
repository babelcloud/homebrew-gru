.PHONY: help update-gbox test-gbox

REPO := babelcloud/gbox

.DEFAULT_GOAL := help

help: ## Show this help message
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' Makefile | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

update-gbox: ## Update gbox.rb formula to latest version or specified version (usage: make update-gbox [VERSION=x.x.x])
	@if [ -n "$(VERSION)" ]; then \
		bin/update-gbox.sh -v $(VERSION); \
	else \
		bin/update-gbox.sh; \
	fi

test-gbox: ## Test gbox formula locally with latest version or specified version (usage: make test-gbox [VERSION=x.x.x] [SKIP_CLEANUP=true])
	@if [ -n "$(VERSION)" ]; then \
		if [ "$(SKIP_CLEANUP)" = "true" ]; then \
			bin/test-gbox.sh -v $(VERSION) -s; \
		else \
			bin/test-gbox.sh -v $(VERSION); \
		fi; \
	else \
		if [ "$(SKIP_CLEANUP)" = "true" ]; then \
			bin/test-gbox.sh -s; \
		else \
			bin/test-gbox.sh; \
		fi; \
	fi
