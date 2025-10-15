#!/bin/bash

set -euo pipefail -x

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Requires GitHub CLI (gh) to be installed and configured
# In GitHub Actions, gh is available by default with GITHUB_TOKEN

# Change to the directory where this script is located
cd "$(dirname "${BASH_SOURCE[0]}")"

# Default values
REPO="babelcloud/gbox"
VERSION=""
AUTO_DETECT=true

# Help function
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -v, --version VERSION    Specify version to update to
    -r, --repo REPO          Repository (default: babelcloud/gbox)
    -h, --help               Show this help message

Examples:
    $0                        # Auto-detect latest version
    $0 -v 0.1.12            # Update to specific version
    $0 --version 0.1.12     # Update to specific version

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            VERSION="$2"
            AUTO_DETECT=false
            shift 2
            ;;
        -r|--repo)
            REPO="$2"
            shift 2
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



# Function to get SHA256 for a platform
get_sha256() {
    local os="$1"
    local arch="$2"
    local version="$3"
    local repo="$4"
    local release_url="https://github.com/$repo/releases/download/v$version"
    
    echo "Getting SHA256 for $os-$arch..." >&2
    
    # Try to get from .sha256 file first
    local sha256_file="$release_url/gbox-$os-$arch-$version.tar.gz.sha256"
    local sha256
    sha256=$(curl -sfL "$sha256_file" 2>/dev/null | tr -s ' ' | cut -d ' ' -f 1)
    
    if [[ -n "$sha256" ]]; then
        echo "$sha256"
        return 0
    fi
    
    # If no .sha256 file, calculate from tar.gz
    echo "SHA256 file not found for $os-$arch, calculating from tar.gz..." >&2
    local tar_url="$release_url/gbox-$os-$arch-$version.tar.gz"
    sha256=$(curl -sL "$tar_url" | shasum -a 256 | cut -d ' ' -f 1)
    
    if [[ -n "$sha256" ]]; then
        echo "$sha256"
        return 0
    fi
    
    echo -e "${RED}Error: Failed to get SHA256 for $os-$arch${NC}" >&2
    return 1
}

# Function to check if update is needed
check_update_needed() {
    local version="$1"
    
    # Check if gbox.rb exists
    if [[ ! -f "../gbox.rb" ]]; then
        echo -e "${RED}Error: gbox.rb not found in parent directory${NC}"
        exit 1
    fi
    
    # Get current version from gbox.rb
    local current_version
    current_version=$(grep 'GBOX_VERSION = "' "../gbox.rb" | sed 's/.*GBOX_VERSION = "\([^"]*\)".*/\1/')
    
    if [[ -z "$current_version" ]]; then
        echo -e "${RED}Error: Could not extract current version from gbox.rb${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}Current version: $current_version${NC}"
    echo -e "${YELLOW}Target version: $version${NC}"
    
    if [[ "$current_version" == "$version" ]]; then
        echo -e "${GREEN}No update needed - versions are the same${NC}"
        return 1
    else
        echo -e "${GREEN}Update needed - current: $current_version, target: $version${NC}"
        return 0
    fi
}

# Function to update gbox.rb
update_formula() {
    local version="$1"
    local repo="$2"
    
    echo -e "${YELLOW}Updating gbox.rb to version $version...${NC}"
    
    # Verify release exists
    echo "Verifying release v$version exists..."
    
    # Check if gh is available
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}Error: GitHub CLI (gh) is not installed${NC}" >&2
        exit 1
    fi
    
    # Verify gh authentication
    echo "Verifying GitHub CLI authentication..."
    if ! gh auth status >/dev/null 2>&1; then
        echo -e "${RED}Error: GitHub CLI is not authenticated${NC}" >&2
        echo -e "${YELLOW}Please run: gh auth login${NC}" >&2
        exit 1
    fi
    echo -e "${GREEN}GitHub CLI authentication verified${NC}"
    
    if ! gh release view "v$version" --repo "$repo" >/dev/null 2>&1; then
        echo -e "${RED}Error: Release v$version not found in $repo${NC}"
        exit 1
    fi
    
    echo "Release v$version verified successfully"
    
    # Get SHA256 for each platform
    echo "Calculating SHA256 checksums..."
    local darwin_arm64_sha256 darwin_amd64_sha256 linux_arm64_sha256 linux_amd64_sha256
    
    darwin_arm64_sha256=$(get_sha256 "darwin" "arm64" "$version" "$repo")
    darwin_amd64_sha256=$(get_sha256 "darwin" "amd64" "$version" "$repo")
    linux_arm64_sha256=$(get_sha256 "linux" "arm64" "$version" "$repo")
    linux_amd64_sha256=$(get_sha256 "linux" "amd64" "$version" "$repo")
    
    # Update gbox.rb
    echo "Updating gbox.rb..."
    
    # Determine sed flags based on OS and perform updates
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS sed requires -i '' for in-place editing
        sed -i '' \
            -e 's/GBOX_VERSION = ".*"/GBOX_VERSION = "'"$version"'"/' \
            -e 's/DARWIN_ARM64_SHA256 = ".*"/DARWIN_ARM64_SHA256 = "'"$darwin_arm64_sha256"'"/' \
            -e 's/DARWIN_AMD64_SHA256 = ".*"/DARWIN_AMD64_SHA256 = "'"$darwin_amd64_sha256"'"/' \
            -e 's/LINUX_ARM64_SHA256  = ".*"/LINUX_ARM64_SHA256  = "'"$linux_arm64_sha256"'"/' \
            -e 's/LINUX_AMD64_SHA256  = ".*"/LINUX_AMD64_SHA256  = "'"$linux_amd64_sha256"'"/' \
            "../gbox.rb"
    else
        # Linux sed uses -i for in-place editing
        sed -i \
            -e 's/GBOX_VERSION = ".*"/GBOX_VERSION = "'"$version"'"/' \
            -e 's/DARWIN_ARM64_SHA256 = ".*"/DARWIN_ARM64_SHA256 = "'"$darwin_arm64_sha256"'"/' \
            -e 's/DARWIN_AMD64_SHA256 = ".*"/DARWIN_AMD64_SHA256 = "'"$darwin_amd64_sha256"'"/' \
            -e 's/LINUX_ARM64_SHA256  = ".*"/LINUX_ARM64_SHA256  = "'"$linux_arm64_sha256"'"/' \
            -e 's/LINUX_AMD64_SHA256  = ".*"/LINUX_AMD64_SHA256  = "'"$linux_amd64_sha256"'"/' \
            "../gbox.rb"
    fi
    
    echo -e "${GREEN}Formula updated successfully!${NC}"
}

# Main execution
main() {
    echo -e "${GREEN}=== Gbox Formula Updater ===${NC}"
    
    # Get version
    if [[ "$AUTO_DETECT" == true ]]; then
        VERSION=$(./get-latest-version.sh -r "$REPO" -q)
        if [[ $? -ne 0 ]]; then
            echo -e "${RED}Error: Failed to get latest version${NC}"
            exit 1
        fi
    fi
    
    if [[ -z "$VERSION" ]]; then
        echo -e "${RED}Error: No version specified and auto-detection failed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Target version: $VERSION${NC}"
    
    # Check if update is needed
    if ! check_update_needed "$VERSION"; then
        echo -e "${GREEN}No update needed. Exiting.${NC}"
        exit 0
    fi
    
    # Update the formula
    update_formula "$VERSION" "$REPO"
    
    echo -e "${GREEN}Update completed successfully!${NC}"
}

# Run main function
main "$@"
