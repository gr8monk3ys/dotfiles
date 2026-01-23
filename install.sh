#!/usr/bin/env bash
#
# Dotfiles One-Command Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/gr8monk3ys/dotfiles/main/install.sh | bash
#
# This script:
# 1. Clones the dotfiles repository
# 2. Runs the appropriate installation for your OS
# 3. Sets up symlinks and configurations
#

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Configuration
readonly DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/gr8monk3ys/dotfiles.git}"
readonly DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
readonly DOTFILES_BRANCH="${DOTFILES_BRANCH:-main}"

# Helper functions
print_header() {
    echo -e "\n${BLUE}==>${NC} ${1}"
}

print_success() {
    echo -e "${GREEN}✓${NC} ${1}"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} ${1}"
}

print_error() {
    echo -e "${RED}✗${NC} ${1}"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin)
            echo "macos"
            ;;
        Linux)
            if [[ -f /etc/arch-release ]]; then
                echo "arch"
            else
                echo "linux"
            fi
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking prerequisites..."

    local missing=()

    if ! command_exists git; then
        missing+=("git")
    fi

    if ! command_exists curl; then
        missing+=("curl")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        print_error "Missing required tools: ${missing[*]}"
        echo ""
        echo "Please install them first:"

        local os
        os=$(detect_os)

        case "$os" in
            macos)
                echo "  xcode-select --install"
                ;;
            arch)
                echo "  sudo pacman -S ${missing[*]}"
                ;;
            *)
                echo "  sudo apt-get install ${missing[*]}"
                ;;
        esac

        exit 1
    fi

    print_success "All prerequisites met"
}

# Clone or update repository
setup_repository() {
    print_header "Setting up dotfiles repository..."

    if [[ -d "$DOTFILES_DIR" ]]; then
        print_warning "Dotfiles directory already exists at $DOTFILES_DIR"
        echo ""
        read -p "Do you want to update it? [y/N] " -n 1 -r
        echo ""

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_header "Updating existing repository..."
            cd "$DOTFILES_DIR"
            git fetch origin "$DOTFILES_BRANCH"
            git reset --hard "origin/$DOTFILES_BRANCH"
            print_success "Repository updated"
        else
            print_warning "Using existing repository"
        fi
    else
        print_header "Cloning dotfiles repository..."
        git clone --branch "$DOTFILES_BRANCH" "$DOTFILES_REPO" "$DOTFILES_DIR"
        print_success "Repository cloned to $DOTFILES_DIR"
    fi
}

# Prompt for machine type
setup_machine_type() {
    print_header "Machine profile setup..."

    local machine_type_file="$HOME/.machine_type"

    if [[ -f "$machine_type_file" ]]; then
        local current_type
        current_type=$(cat "$machine_type_file")
        print_success "Machine type already set to: $current_type"
        return
    fi

    echo ""
    echo "What type of machine is this?"
    echo "  1) personal - Personal computer"
    echo "  2) work     - Work computer"
    echo "  3) server   - Server/headless"
    echo ""
    read -p "Select [1-3, default: 1]: " -n 1 -r
    echo ""

    local machine_type
    case "$REPLY" in
        2) machine_type="work" ;;
        3) machine_type="server" ;;
        *) machine_type="personal" ;;
    esac

    echo "$machine_type" > "$machine_type_file"
    print_success "Machine type set to: $machine_type"
}

# Run installation
run_installation() {
    print_header "Running installation..."

    cd "$DOTFILES_DIR"

    local os
    os=$(detect_os)

    case "$os" in
        macos)
            print_header "Detected macOS - running full installation"
            make macos
            ;;
        arch)
            print_header "Detected Arch Linux - running full installation"
            make arch
            ;;
        *)
            print_warning "Unknown OS - running link-only installation"
            make link
            ;;
    esac
}

# Post-installation message
print_post_install() {
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  Dotfiles installation complete!${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Restart your terminal or run: source ~/.zshenv"
    echo "  2. Run 'p10k configure' to set up your prompt"
    echo "  3. Check installation with: make doctor"
    echo ""
    echo "Useful commands:"
    echo "  make update  - Update all packages"
    echo "  make backup  - Backup current configuration"
    echo "  make doctor  - Run health check"
    echo ""
    echo "For local customizations, create:"
    echo "  ~/.config/zsh/zshrc.local"
    echo "  ~/.config/git/config.local"
    echo ""
    echo -e "Repository: ${BLUE}$DOTFILES_DIR${NC}"
    echo ""
}

# Main function
main() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║      Dotfiles Installer                ║${NC}"
    echo -e "${BLUE}║      github.com/gr8monk3ys/dotfiles    ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""

    check_prerequisites
    setup_repository
    setup_machine_type
    run_installation
    print_post_install
}

# Run main function
main "$@"
