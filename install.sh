#!/usr/bin/env bash
#
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  Lorenzo's Dotfiles - One-Command Installer                               ║
# ║  https://github.com/gr8monk3ys/dotfiles                                   ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
#
# Usage: curl -fsSL https://raw.githubusercontent.com/gr8monk3ys/dotfiles/main/install.sh | bash
#

set -euo pipefail

# ============================================================================
# OneDark Theme Colors
# ============================================================================
readonly BLACK='\033[38;2;40;44;52m'      # #282c34
readonly RED='\033[38;2;224;108;117m'     # #e06c75
readonly GREEN='\033[38;2;152;195;121m'   # #98c379
readonly YELLOW='\033[38;2;229;192;123m'  # #e5c07b
readonly BLUE='\033[38;2;97;175;239m'     # #61afef
readonly MAGENTA='\033[38;2;198;120;221m' # #c678dd
readonly CYAN='\033[38;2;86;182;194m'     # #56b6c2
readonly WHITE='\033[38;2;171;178;191m'   # #abb2bf
readonly ORANGE='\033[38;2;209;154;102m'  # #d19a66
readonly NC='\033[0m'                      # No Color
readonly BOLD='\033[1m'
readonly DIM='\033[2m'

# ============================================================================
# Configuration
# ============================================================================
readonly DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/gr8monk3ys/dotfiles.git}"
readonly DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
readonly DOTFILES_BRANCH="${DOTFILES_BRANCH:-main}"
readonly DOTFILES_STRICT_PACKAGES="${DOTFILES_STRICT_PACKAGES:-1}"

# ============================================================================
# ASCII Art Banner
# ============================================================================
print_banner() {
    echo ""
    echo -e "${MAGENTA}${BOLD}"
    cat << 'EOF'
    ██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗
    ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝██╔════╝
    ██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗
    ██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║
    ██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║
    ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝
EOF
    echo -e "${NC}"
    echo ""
    echo -e "    ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "    ${WHITE}${BOLD}  A keyboard-driven development environment${NC}"
    echo -e "    ${DIM}  github.com/gr8monk3ys/dotfiles${NC}"
    echo -e "    ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# ============================================================================
# Helper Functions
# ============================================================================
print_step() {
    echo -e "\n${BLUE}${BOLD}▶${NC} ${WHITE}${BOLD}$1${NC}"
}

print_substep() {
    echo -e "  ${CYAN}→${NC} $1"
}

print_success() {
    echo -e "  ${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "  ${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "  ${RED}✗${NC} $1"
}

print_info() {
    echo -e "  ${DIM}$1${NC}"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

is_interactive() {
    [[ -t 0 && -t 1 ]]
}

# ============================================================================
# System Detection
# ============================================================================
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

detect_arch() {
    case "$(uname -m)" in
        arm64|aarch64)
            echo "arm64"
            ;;
        x86_64)
            echo "x86_64"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# ============================================================================
# Prerequisites Check
# ============================================================================
check_prerequisites() {
    print_step "Checking prerequisites"

    local missing=()

    if ! command_exists git; then
        missing+=("git")
    else
        print_success "git $(git --version | cut -d' ' -f3)"
    fi

    if ! command_exists curl; then
        missing+=("curl")
    else
        print_success "curl found"
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        print_error "Missing required tools: ${missing[*]}"
        echo ""
        print_info "Please install them first:"

        local os
        os=$(detect_os)

        case "$os" in
            macos)
                print_info "  xcode-select --install"
                ;;
            arch)
                print_info "  sudo pacman -S ${missing[*]}"
                ;;
            *)
                print_info "  sudo apt-get install ${missing[*]}"
                ;;
        esac

        exit 1
    fi

    # Show detected system info
    local os arch
    os=$(detect_os)
    arch=$(detect_arch)
    print_success "System: $os ($arch)"
}

# ============================================================================
# Repository Setup
# ============================================================================
setup_repository() {
    print_step "Setting up dotfiles repository"

    if [[ -d "$DOTFILES_DIR" ]]; then
        print_warning "Dotfiles directory already exists"
        print_info "$DOTFILES_DIR"
        echo ""
        local update_repo="false"
        if [[ -n "${DOTFILES_ASSUME_YES:-}" ]]; then
            update_repo="true"
        elif is_interactive; then
            read -p "    Update existing repository? [y/N] " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                update_repo="true"
            fi
        else
            print_info "Non-interactive mode detected; skipping update prompt"
        fi

        if [[ "$update_repo" == "true" ]]; then
            print_substep "Updating repository..."
            cd "$DOTFILES_DIR"
            # Fast-forward only: never discard local commits or edits.
            if git pull --ff-only origin "$DOTFILES_BRANCH"; then
                print_success "Repository updated"
            else
                print_error "Could not fast-forward $DOTFILES_DIR to origin/$DOTFILES_BRANCH"
                print_info "Local commits or uncommitted changes are in the way."
                print_info "Resolve by hand (git status / git rebase origin/$DOTFILES_BRANCH), then re-run."
                exit 1
            fi
        else
            print_info "Using existing repository"
        fi
    else
        print_substep "Cloning repository..."
        git clone --branch "$DOTFILES_BRANCH" "$DOTFILES_REPO" "$DOTFILES_DIR"
        print_success "Cloned to $DOTFILES_DIR"
    fi
}

# ============================================================================
# Machine Profile Setup
# ============================================================================
setup_machine_type() {
    print_step "Machine profile configuration"

    local machine_type_file="$HOME/.machine_type"

    if [[ -f "$machine_type_file" ]]; then
        local current_type
        current_type=$(cat "$machine_type_file")
        print_success "Profile already set: $current_type"
        return
    fi

    local machine_type="${DOTFILES_MACHINE_TYPE:-}"
    if [[ -n "$machine_type" ]]; then
        print_info "Using DOTFILES_MACHINE_TYPE=$machine_type"
    elif ! is_interactive; then
        machine_type="personal"
        print_info "Non-interactive mode detected; defaulting to: $machine_type"
    else
        echo ""
        echo -e "    ${WHITE}What type of machine is this?${NC}"
        echo ""
        echo -e "    ${CYAN}1)${NC} personal  ${DIM}- Personal workstation${NC}"
        echo -e "    ${CYAN}2)${NC} work      ${DIM}- Work/corporate machine${NC}"
        echo -e "    ${CYAN}3)${NC} server    ${DIM}- Server/headless system${NC}"
        echo ""
        read -p "    Select [1-3, default: 1]: " -n 1 -r
        echo ""

        case "$REPLY" in
            2) machine_type="work" ;;
            3) machine_type="server" ;;
            *) machine_type="personal" ;;
        esac
    fi

    echo "$machine_type" > "$machine_type_file"
    print_success "Profile set to: $machine_type"
}

# ============================================================================
# Installation
# ============================================================================
run_installation() {
    print_step "Running installation"

    cd "$DOTFILES_DIR"

    local os
    os=$(detect_os)

    case "$os" in
        macos)
            print_substep "Detected macOS - running full installation"
            print_info "This may take a while..."
            if [[ "$DOTFILES_STRICT_PACKAGES" == "1" ]]; then
                print_info "Strict package mode enabled (installation fails on package errors)"
                BREW_BUNDLE_STRICT=1 make macos
            else
                make macos
            fi
            ;;
        arch)
            print_substep "Detected Arch Linux - running full installation"
            make arch
            ;;
        *)
            print_warning "Unknown OS - running symlink-only installation"
            print_info "Package installation is not configured for this OS."
            make link
            ;;
    esac
}

# ============================================================================
# Post-Installation
# ============================================================================
print_post_install() {
    echo ""
    echo -e "${GREEN}${BOLD}    ✓ Installation complete${NC}"
    echo ""

    echo -e "    ${WHITE}${BOLD}Next Steps:${NC}"
    echo ""
    echo -e "    ${CYAN}1.${NC} Restart your terminal or run:"
    echo -e "       ${DIM}source ~/.zshenv${NC}"
    echo ""
    echo -e "    ${CYAN}2.${NC} Prompt is Starship (config: ~/.config/starship/starship.toml)"
    echo ""
    echo -e "    ${CYAN}3.${NC} Verify installation:"
    echo -e "       ${DIM}make doctor${NC}"
    echo ""
    echo -e "    ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "    ${WHITE}${BOLD}Useful Commands:${NC}"
    echo ""
    echo -e "    ${MAGENTA}make update${NC}    ${DIM}- Update all packages${NC}"
    echo -e "    ${MAGENTA}make backup${NC}    ${DIM}- Backup configurations${NC}"
    echo -e "    ${MAGENTA}make doctor${NC}    ${DIM}- Run health check${NC}"
    echo ""
    echo -e "    ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "    ${WHITE}${BOLD}Local Customization:${NC}"
    echo ""
    echo -e "    ${DIM}Create these files for machine-specific settings:${NC}"
    echo -e "    ${ORANGE}~/.config/zsh/zshrc.local${NC}"
    echo -e "    ${ORANGE}~/.config/git/config.local${NC}"
    echo ""
    echo -e "    ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "    Repository: ${BLUE}$DOTFILES_DIR${NC}"
    echo ""
}

# ============================================================================
# Main Entry Point
# ============================================================================
main() {
    print_banner
    check_prerequisites
    setup_repository
    setup_machine_type
    run_installation
    print_post_install
}

# Run main function
main "$@"
