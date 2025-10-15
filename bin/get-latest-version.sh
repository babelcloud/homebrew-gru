#!/bin/bash

set -euo pipefail -x

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Requires GitHub CLI (gh) to be installed and configured
# In GitHub Actions, gh is available by default with GITHUB_TOKEN

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

Examples:
    $0                            # Get latest stable version
    $0 -p                        # Get latest version including pre-releases
    $0 -p -d                     # Get latest version including pre-releases and drafts
    $0 --repo other/repo         # Get from different repository
    $0 -q                        # Quiet output (version only)

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
    
    # Check if gh is available
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}Error: GitHub CLI (gh) is not installed${NC}" >&2
        exit 1
    fi
    
    # Verify gh authentication
    if [[ "$QUIET" == false ]]; then
        echo "Verifying GitHub CLI authentication..."
    fi
    if ! gh auth status >/dev/null 2>&1; then
        echo -e "${RED}Error: GitHub CLI is not authenticated${NC}" >&2
        echo -e "${YELLOW}Please run: gh auth login${NC}" >&2
        exit 1
    fi
    if [[ "$QUIET" == false ]]; then
        echo -e "${GREEN}GitHub CLI authentication verified${NC}"
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
    local temp_output
    temp_output=$(mktemp)
    if gh release list --repo "$REPO" --limit 20 --json tagName,isDraft,isPrerelease --jq "$jq_filter" > "$temp_output" 2>/dev/null; then
        latest_version=$(head -1 "$temp_output" | sed 's/v//')
        rm -f "$temp_output"
    else
        rm -f "$temp_output"
        latest_version=""
    fi
    
    if [[ -z "$latest_version" ]]; then
        echo -e "${RED}Error: No valid releases found${NC}" >&2
        exit 1
    fi
    
    if [[ "$QUIET" == false ]]; then
        echo -e "${GREEN}Latest version: $latest_version${NC}"
    fi
    
    echo "$latest_version"
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
