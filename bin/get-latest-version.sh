#!/bin/bash

set -euo pipefail -x

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Smart GitHub integration:
# - If 'gh' CLI is available: Uses GitHub CLI (no token needed locally)
# - If 'gh' CLI is not available: Uses GitHub API with GH_TOKEN (for CI environments)
# Usage: GH_TOKEN=your_token ./get-latest-version.sh  # Force API mode

# Default values
REPO="babelcloud/gbox"
INCLUDE_PRERELEASE=false
INCLUDE_DRAFT=false
QUIET=false

# Help function
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -r, --repo REPO              Repository (default: babelcloud/gbox)
    -p, --include-prerelease     Include pre-release versions
    -d, --include-draft          Include draft versions
    -q, --quiet                  Quiet output (only version number)
    -h, --help                   Show this help message

Environment Variables:
    GH_TOKEN                     GitHub token for API access (only needed when gh CLI is not available)

Behavior:
    - If 'gh' CLI is available: Uses GitHub CLI for release information
    - If 'gh' CLI is not available: Falls back to GitHub API (requires GH_TOKEN in CI)

Examples:
    $0                            # Get latest stable version
    $0 -p                        # Get latest version including pre-releases
    $0 -p -d                     # Get latest version including pre-releases and drafts
    $0 --repo other/repo         # Get from different repository
    $0 -q                        # Quiet output (version only)
    GH_TOKEN=token $0           # Force API mode with token (useful in CI)

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--repo)
            REPO="$2"
            shift 2
            ;;
        -p|--include-prerelease)
            INCLUDE_PRERELEASE=true
            shift
            ;;
        -d|--include-draft)
            INCLUDE_DRAFT=true
            shift
            ;;
        -q|--quiet)
            QUIET=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown option $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Function to get latest version
get_latest_version() {
    if [[ "$QUIET" == false ]]; then
        echo -e "${YELLOW}Getting latest version from $REPO...${NC}"
    fi
    
    if command -v gh >/dev/null 2>&1; then
        # Use GitHub CLI if available
        if [[ "$QUIET" == false ]]; then
            echo "Using GitHub CLI..."
        fi
        
        # Build jq filter based on options
        local jq_filter=".[]"
        
        if [[ "$INCLUDE_DRAFT" == false ]] && [[ "$INCLUDE_PRERELEASE" == false ]]; then
            jq_filter=".[] | select(.isDraft == false and .isPrerelease == false)"
        elif [[ "$INCLUDE_DRAFT" == false ]]; then
            jq_filter=".[] | select(.isDraft == false)"
        elif [[ "$INCLUDE_PRERELEASE" == false ]]; then
            jq_filter=".[] | select(.isPrerelease == false)"
        fi
        
        jq_filter="$jq_filter | .tagName"
        
        # Get latest version
        local latest_version
        latest_version=$(gh release list --repo "$REPO" --limit 20 --json tagName,isDraft,isPrerelease \
            --jq "$jq_filter" | head -1 | sed 's/v//')
        
        if [[ -n "$latest_version" ]]; then
            if [[ "$QUIET" == false ]]; then
                echo -e "${GREEN}Latest version: $latest_version${NC}"
            fi
            echo "$latest_version"
            return 0
        fi
    else
        # Fallback to GitHub API
        if [[ "$QUIET" == false ]]; then
            echo "Using GitHub API..."
        fi
        
        local latest_version
        if [[ "$INCLUDE_DRAFT" == false ]] && [[ "$INCLUDE_PRERELEASE" == false ]]; then
            # Get latest stable release
            latest_version=$(curl -sfL -H "Authorization: token ${GH_TOKEN:-}" \
                "https://api.github.com/repos/$REPO/releases/latest" | \
                jq -r '.tag_name' | sed 's/v//')
        else
            # Get all releases and filter
            local filter=""
            if [[ "$INCLUDE_DRAFT" == false ]]; then
                filter="$filter and .draft == false"
            fi
            if [[ "$INCLUDE_PRERELEASE" == false ]]; then
                filter="$filter and .prerelease == false"
            fi
            
            if [[ -n "$filter" ]]; then
                filter=" | select(${filter# and })"
            fi
            
            latest_version=$(curl -sfL -H "Authorization: token ${GH_TOKEN:-}" \
                "https://api.github.com/repos/$REPO/releases" | \
                jq -r ".[]$filter | .tag_name" | head -1 | sed 's/v//')
        fi
        
        if [[ -n "$latest_version" ]] && [[ "$latest_version" != "null" ]]; then
            if [[ "$QUIET" == false ]]; then
                echo -e "${GREEN}Latest version: $latest_version${NC}"
            fi
            echo "$latest_version"
            return 0
        fi
    fi
    
    echo -e "${RED}Error: No valid releases found${NC}" >&2
    exit 1
}

# Main execution
main() {
    if [[ "$QUIET" == false ]]; then
        echo -e "${GREEN}=== Latest Version Getter ===${NC}"
        echo -e "${GREEN}Repository: $REPO${NC}"
        echo -e "${GREEN}Include pre-releases: $INCLUDE_PRERELEASE${NC}"
        echo -e "${GREEN}Include drafts: $INCLUDE_DRAFT${NC}"
        echo
    fi
    
    get_latest_version
}

# Run main function
main "$@"
