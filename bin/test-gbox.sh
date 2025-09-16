#!/bin/bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Change to the directory where this script is located
cd "$(dirname "${BASH_SOURCE[0]}")"

# Default values
VERSION=""
TAR_PATH=""
TAP_ORG="gru"
TAP_NAME="gbox-test"
SKIP_CLEANUP=false

# Help function
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -v, --version VERSION    Specify version to test
    -p, --path PATH          Path to tar.gz file (auto-detected if not specified)
    -o, --org ORG            Tap organization (default: gru)
    -n, --name NAME          Tap name (default: gbox-test)
    -s, --skip-cleanup       Skip cleanup step (keep gbox installed)
    -h, --help               Show this help message

Examples:
    $0 -v 0.1.12                    # Test specific version
    $0 -v 0.1.12 -p /path/to/file  # Test with specific tar.gz file
    $0 -v 0.1.12 -s                 # Test and keep gbox installed
    $0 --help                       # Show this help

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -p|--path)
            TAR_PATH="$2"
            shift 2
            ;;
        -o|--org)
            TAP_ORG="$2"
            shift 2
            ;;
        -n|--name)
            TAP_NAME="$2"
            shift 2
            ;;
        -s|--skip-cleanup)
            SKIP_CLEANUP=true
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

# Auto-detect version if not specified
if [[ -z "$VERSION" ]]; then
    echo -e "${YELLOW}No version specified, auto-detecting latest version...${NC}"
    VERSION=$(./get-latest-version.sh -q)
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Error: Failed to get latest version${NC}"
        exit 1
    fi
    echo -e "${GREEN}Auto-detected version: $VERSION${NC}"
fi

# Function to detect system architecture
detect_architecture() {
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64) echo "amd64" ;;
        aarch64) echo "arm64" ;;
        arm64) echo "arm64" ;;
        *) echo "$arch" ;;
    esac
}

# Function to detect OS
detect_os() {
    uname -s | tr '[:upper:]' '[:lower:]'
}

# Function to auto-detect tar.gz path
auto_detect_tar_path() {
    local os arch
    os=$(detect_os)
    arch=$(detect_architecture)
    
    # Try common paths
    local possible_paths=(
        "../../gbox/dist/gbox-$os-$arch-$VERSION.tar.gz"
        "./gbox-$os-$arch-$VERSION.tar.gz"
        "../dist/gbox-$os-$arch-$VERSION.tar.gz"
    )
    
    for path in "${possible_paths[@]}"; do
        if [[ -f "$path" ]]; then
            echo "$path"
            return 0
        fi
    done
    
    echo -e "${RED}Error: Could not auto-detect tar.gz file for $os-$arch-$VERSION${NC}" >&2
    echo -e "${YELLOW}Tried paths:${NC}" >&2
    for path in "${possible_paths[@]}"; do
        echo -e "  - $path" >&2
    done
    return 1
}

# Function to check dependencies
check_dependencies() {
    echo -e "${YELLOW}Checking dependencies...${NC}"
    
    local missing_deps=()
    
    # Check for required commands
    for cmd in brew; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo -e "${RED}Error: Missing required dependencies: ${missing_deps[*]}${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}All dependencies satisfied${NC}"
}

# Function to setup test tap
setup_test_tap() {
    echo -e "${YELLOW}Setting up test tap...${NC}"
    
    local tap_dir="../$TAP_ORG-$TAP_NAME"
    
    # Remove existing tap if it exists
    echo "Removing existing tap..."
    if brew tap | grep -q "$TAP_ORG/$TAP_NAME"; then
        echo "Found existing tap, removing it..."
        brew untap "$TAP_ORG/$TAP_NAME" || {
            echo -e "${YELLOW}Warning: Failed to untap, trying to force remove...${NC}"
            # Force remove the tap directory
            local tap_path="/opt/homebrew/Library/Taps/$TAP_ORG/homebrew-$TAP_NAME"
            if [[ -d "$tap_path" ]]; then
                rm -rf "$tap_path"
            fi
            # Also try Linux path
            tap_path="$HOME/.linuxbrew/Library/Taps/$TAP_ORG/homebrew-$TAP_NAME"
            if [[ -d "$tap_path" ]]; then
                rm -rf "$tap_path"
            fi
        }
    fi
    rm -rf "$tap_dir" 2>/dev/null || true
    
    # Create new tap
    echo "Creating new tap: $TAP_ORG/$TAP_NAME"
    brew tap-new "$TAP_ORG/$TAP_NAME"
    
    # Copy gbox.rb to tap
    local tap_formula_path="/opt/homebrew/Library/Taps/$TAP_ORG/homebrew-$TAP_NAME/Formula/"
    if [[ ! -d "$tap_formula_path" ]]; then
        # Try Linux path
        tap_formula_path="$HOME/.linuxbrew/Library/Taps/$TAP_ORG/homebrew-$TAP_NAME/Formula/"
    fi
    
    if [[ ! -d "$tap_formula_path" ]]; then
        echo -e "${RED}Error: Could not find tap formula directory${NC}"
        exit 1
    fi
    
    echo "Copying gbox.rb to tap..."
    cp ../gbox.rb "$tap_formula_path/"
    
    echo -e "${GREEN}Test tap setup completed${NC}"
}

# Function to test installation
test_installation() {
    echo -e "${YELLOW}Testing gbox installation...${NC}"
    
    # Uninstall existing gbox if present
    echo "Uninstalling existing gbox..."
    brew uninstall gbox 2>/dev/null || true
    
    # Install from test tap
    echo "Installing gbox from test tap..."
    # Convert relative path to absolute path
    local abs_tar_path
    if [[ "$TAR_PATH" = /* ]]; then
        abs_tar_path="$TAR_PATH"
    else
        abs_tar_path="$(realpath "$TAR_PATH")"
    fi
    env HOMEBREW_GBOX_VERSION="$VERSION" HOMEBREW_GBOX_URL="file://$abs_tar_path" \
        brew install --build-from-source "$TAP_ORG/$TAP_NAME/gbox"
    
    # Test the installation
    echo "Testing gbox installation..."
    if gbox --version; then
        echo -e "${GREEN}gbox installation test successful!${NC}"
    else
        echo -e "${RED}gbox installation test failed!${NC}"
        exit 1
    fi
}

# Function to cleanup
cleanup() {
    echo -e "${YELLOW}Cleaning up...${NC}"
    
    # Uninstall gbox
    brew uninstall gbox 2>/dev/null || true
    
    # Remove test tap
    brew untap "$TAP_ORG/$TAP_NAME" 2>/dev/null || true
    
    echo -e "${GREEN}Cleanup completed${NC}"
}

# Main execution
main() {
    echo -e "${GREEN}=== Gbox Formula Tester ===${NC}"
    echo -e "${GREEN}Version: $VERSION${NC}"
    
    # Check dependencies
    check_dependencies
    
    # Auto-detect tar.gz path if not specified
    if [[ -z "$TAR_PATH" ]]; then
        echo -e "${YELLOW}Auto-detecting tar.gz file...${NC}"
        TAR_PATH=$(auto_detect_tar_path)
    fi
    
    # Verify tar.gz file exists
    if [[ ! -f "$TAR_PATH" ]]; then
        echo -e "${RED}Error: Tar.gz file not found: $TAR_PATH${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Using tar.gz file: $TAR_PATH${NC}"
    
    # Setup test environment
    setup_test_tap
    
    # Test installation
    test_installation
    
    # Cleanup (unless skipped)
    if [[ "$SKIP_CLEANUP" == true ]]; then
        echo -e "${GREEN}Test completed successfully!${NC}"
        echo -e "${YELLOW}Note: Cleanup skipped - gbox is still installed${NC}"
        echo -e "${YELLOW}To uninstall gbox later, run: brew uninstall gbox${NC}"
    else
        # Cleanup
        cleanup
        echo -e "${GREEN}Test completed successfully!${NC}"
    fi
}

# Trap cleanup on exit (unless skipped)
if [[ "$SKIP_CLEANUP" != true ]]; then
    trap cleanup EXIT
fi

# Run main function
main "$@"
