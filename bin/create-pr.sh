#!/bin/bash

set -euo pipefail

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
BRANCH_PREFIX="update-gbox-to-v"
BASE_BRANCH="main"
COMMIT_MESSAGE=""
PR_TITLE=""
PR_BODY=""

# Help function
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -m, --message MESSAGE    Custom commit message
    -t, --title TITLE        Custom PR title
    -b, --body BODY          Custom PR body
    -p, --prefix PREFIX      Branch prefix (default: update-gbox-to-v)
    -r, --base-branch BRANCH Base branch (default: main)
    -h, --help               Show this help message


Examples:
    $0                                    # Auto-create PR with default settings
    $0 -m "Custom commit message"        # Custom commit message
    $0 -t "Custom PR title"              # Custom PR title
    $0 --body "Custom PR body"           # Custom PR body

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--message)
            COMMIT_MESSAGE="$2"
            shift 2
            ;;
        -t|--title)
            PR_TITLE="$2"
            shift 2
            ;;
        -b|--body)
            PR_BODY="$2"
            shift 2
            ;;
        -p|--prefix)
            BRANCH_PREFIX="$2"
            shift 2
            ;;
        -r|--base-branch)
            BASE_BRANCH="$2"
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

# Function to check if there are changes
check_changes() {
    echo -e "${YELLOW}Checking for changes...${NC}"
    
    if git diff --quiet; then
        echo -e "${GREEN}No changes detected. Skipping PR creation.${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Changes detected. Proceeding with PR creation.${NC}"
    return 0
}

# Function to get updated version
get_updated_version() {
    local version
    version=$(grep 'GBOX_VERSION = "' "../gbox.rb" | sed 's/.*GBOX_VERSION = "\([^"]*\)".*/\1/')
    
    if [[ -z "$version" ]]; then
        echo -e "${RED}Error: Could not extract version from gbox.rb${NC}"
        exit 1
    fi
    
    echo "$version"
}

# Function to configure git
configure_git() {
    echo -e "${YELLOW}Configuring git...${NC}"
    
    # Check if running in GitHub Actions
    if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
        # Running in GitHub Actions
        git config --local user.email "gh_action@gbox.ai"
        git config --local user.name "GitHub Action"
        echo -e "${GREEN}Configured git for GitHub Actions${NC}"
    else
        # Running locally - use existing git config or prompt for setup
        local current_email current_name
        
        current_email=$(git config --global user.email 2>/dev/null || echo "")
        current_name=$(git config --global user.name 2>/dev/null || echo "")
        
        if [[ -n "$current_email" && -n "$current_name" ]]; then
            echo -e "${GREEN}Using existing git config: $current_name <$current_email>${NC}"
        else
            echo -e "${RED}Error: Git user configuration not found${NC}"
            echo -e "${YELLOW}Please configure git with:${NC}"
            echo -e "  git config --global user.name \"Your Name\""
            echo -e "  git config --global user.email \"your.email@example.com\""
            exit 1
        fi
    fi
}

# Function to create pull request using gh
create_pull_request() {
    local version="$1"
    local title="$PR_TITLE"
    local body="$PR_BODY"
    local commit_msg="$COMMIT_MESSAGE"
    local branch_name="$BRANCH_PREFIX$version"
    
    # Use default commit message if not provided
    if [[ -z "$commit_msg" ]]; then
        commit_msg="Update Gbox to version $version"
    fi
    
    # Use default title if not provided
    if [[ -z "$title" ]]; then
        title="Update Gbox to version $version"
    fi
    
    # Use default body if not provided
    if [[ -z "$body" ]]; then
        body="This PR automatically updates the Gbox formula to version $version.

## Changes
- Updated GBOX_VERSION to $version
- Updated SHA256 checksums for all platforms

## Auto-generated
This PR was automatically created by the GitHub Action workflow."
    fi
    
    echo -e "${YELLOW}Creating pull request...${NC}"
    
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
    
    # Use gh to create PR with automatic branch creation and push
    echo -e "${YELLOW}Creating branch and PR using gh...${NC}"
    gh pr create \
        --title "$title" \
        --body "$body" \
        --base "$BASE_BRANCH" \
        --head "$branch_name" \
        --draft=false
    
    echo -e "${GREEN}Pull request created successfully!${NC}"
}

# Main execution
main() {
    echo -e "${GREEN}=== PR Creator ===${NC}"
    
    # Check if there are changes
    if ! check_changes; then
        exit 0
    fi
    
    # Get updated version
    local version
    version=$(get_updated_version)
    echo -e "${GREEN}Updated version: $version${NC}"
    
    # Configure git
    configure_git
    
    # Create pull request directly using gh
    create_pull_request "$version"
    
    echo -e "${GREEN}PR creation completed successfully!${NC}"
}

# Run main function
main "$@"
