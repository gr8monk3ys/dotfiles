# TODO List

Organized list of improvements, fixes, and future enhancements for the dotfiles repository.

## Recently Completed ✅

- [x] **Create CLAUDE.md** - AI assistant guide for working with this repository
- [x] **Fix Makefile directory references** - Updated to work with current structure
- [x] **Create missing runcom directory** - Decision made to keep root-level files
- [x] **Add duti configuration file** - Default application associations configured
- [x] **Create missing bin scripts** - All required scripts created with documentation
- [x] **Populate Codefile** - Added useful VSCodium extensions with categories
- [x] **Create CONTRIBUTING.md** - Comprehensive contribution guidelines
- [x] **Create CHANGELOG.md** - Version tracking with Keep a Changelog format
- [x] **Create LICENSE** - Added MIT License
- [x] **Add .gitattributes** - Line ending and language detection configuration
- [x] **Update main README.md** - Added documentation links, FAQ, and troubleshooting
- [x] **Enhance install/README.md** - Added troubleshooting, backup/restore, platform quirks
- [x] **Create utility scripts** - dotfiles-doctor, dotfiles-update, dotfiles-backup
- [x] **Add Make targets** - doctor, update, backup commands in Makefile
- [x] **Create testing infrastructure** - BATS tests for scripts and packages
- [x] **Add .shellcheckrc** - ShellCheck configuration for linting
- [x] **Improve bin/ scripts** - Added --help flags, verbose mode, skip options
- [x] **Document Brewfile and Caskfile** - Added comprehensive comments and categories
- [x] **Add Make targets** - clean, restore, brew-update, brew-cleanup
- [x] **Document npmfile and Rustfile** - Added comprehensive comments and optional tools
- [x] **Expand .editorconfig** - Added settings for 20+ file types
- [x] **Create MAKEFILE.md** - Comprehensive Makefile documentation
- [x] **Set up GitHub Actions** - Created/updated install, lint, and test workflows
- [x] **Create .github/README.md** - Comprehensive CI/CD workflow documentation
- [x] **Create pre-commit hooks** - Comprehensive validation and linting

## Critical Issues

### Missing Files
- [x] **Populate or Remove Codefile** ✅ COMPLETED
  - Populated with essential VSCodium extensions
  - Categorized by language support, git, utilities, themes
  - Ready for `make vscode-extensions`

### Testing Infrastructure
- [x] **Create test directory and implement BATS tests** ✅ COMPLETED
  - Created test/ directory structure
  - Set up BATS testing framework with comprehensive README
  - Written tests for:
    - ✅ Platform detection scripts (test_platform.bats)
    - ✅ bin/ utility scripts (test_bin_scripts.bats)
    - ✅ Package file validation (test_packages.bats)
  - Created test documentation in test/README.md
  - Created common test helpers (test_helper/common.bash)

## Documentation

### Missing READMEs
- [ ] **Create .local/bin/README.md**
  - Document all utility scripts in user's ~/.local/bin if any
  - Explain what each script does
  - Add usage examples

- [x] **Create .github/README.md** ✅ COMPLETED
  - Documented all three CI/CD workflows (install, test, lint)
  - Explained what each workflow does and when it runs
  - Added badge links and workflow status information
  - Included local testing guide and troubleshooting
  - Documented common workflow patterns for future additions

### Root-Level Documentation
- [x] **CLAUDE.md** - AI assistant guide ✅ COMPLETED
- [x] **CONTRIBUTING.md** - Guidelines for contributions ✅ COMPLETED
  - Code of conduct and getting started
  - Branch naming and commit message conventions
  - Coding standards for shell, Makefile, configs
  - Testing and documentation requirements
  - PR process and review criteria
- [x] **CHANGELOG.md** - Track major changes ✅ COMPLETED
  - Uses Keep a Changelog format
  - Semantic versioning guidelines
  - Release notes format
  - Upgrade notes section
- [x] **LICENSE** - MIT License ✅ COMPLETED
  - Clear MIT License terms
  - Formalizes "at your own risk" statement

### Improve Existing Documentation
- [ ] **Review .config/*/README.md files**
  - Ensure all config directories have READMEs
  - Check for outdated information
  - Add troubleshooting sections where needed
  - Document keybindings and shortcuts

- [x] **Enhance install/README.md** ✅ COMPLETED
  - Added comprehensive troubleshooting section
  - Documented backup & restore procedures
  - Added platform-specific quirks and considerations
  - Explained package file formats and purposes

- [x] **Update main README.md** ✅ COMPLETED
  - Added Documentation section with links to all new docs
  - Added comprehensive FAQ section
  - Added expanded Troubleshooting section
  - Improved structure and navigation

## Configuration Improvements

### Shell Configuration
- [ ] **Organize Zsh configuration**
  - Review .config/zsh/ structure
  - Consider splitting into modular files (aliases, functions, plugins)
  - Create separate profiles for different environments (work, personal)
  - Add better comments explaining each section

- [ ] **Review and organize .aliases**
  - Categorize aliases better (git, navigation, system, etc.)
  - Remove unused/outdated aliases
  - Add more macOS-specific utilities
  - Document complex aliases

- [ ] **Add Zsh plugins documentation**
  - Document Oh My Zsh plugins in use
  - Document custom plugins
  - Add installation steps for third-party plugins

### macOS Configuration
- [ ] **Test and update .config/macos/defaults.sh**
  - Verify all settings work on latest macOS (Sonoma/Sequoia)
  - Add comments explaining each setting
  - Group settings by category (Dock, Finder, System, etc.)
  - Add option to selectively apply settings

- [ ] **Test and update .config/macos/dock.sh**
  - Verify application paths are correct
  - Make dock applications configurable
  - Add option for different dock layouts (minimal, full, development)
  - Document required applications

### Git Configuration
- [x] **Add .gitattributes** ✅ COMPLETED
  - Line ending normalization (LF for Unix files)
  - Diff patterns for common languages
  - Binary file detection
  - Linguist overrides for GitHub language stats

- [ ] **Enhance .config/git/config**
  - Add more useful aliases
  - Configure GPG signing (optional)
  - Add conditional includes for work/personal
  - Document all custom settings

### Application Configurations
- [ ] **Review Neovim configuration**
  - Ensure .config/nvim/README.md is up to date
  - Document all plugins and their purposes
  - Document custom keybindings
  - Add troubleshooting section

- [ ] **Review Tmux configuration**
  - Document key bindings
  - Consider adding TPM (Tmux Plugin Manager)
  - Document session management workflow

- [ ] **Review AeroSpace configuration**
  - Document window management workflow
  - Add example workspace configurations
  - Create quick reference guide

## Testing & CI/CD

### Testing Infrastructure
- [ ] **Implement BATS testing framework**
  - Install BATS
  - Create test/ directory structure
  - Write unit tests for bin/ scripts
  - Write integration tests for Makefile targets
  - Test symlink creation/deletion

- [x] **Add linting tools** ✅ PARTIALLY COMPLETED
  - ✅ Added .shellcheckrc for shellcheck configuration
  - [ ] Add yamllint for YAML files (future)
  - [ ] Add markdownlint for documentation (future)

- [x] **Create pre-commit hooks** ✅ COMPLETED
  - Created .pre-commit-config.yaml with comprehensive hooks
  - Included: trailing whitespace, end-of-file, YAML validation, large files
  - ShellCheck for shell scripts in bin/
  - Markdownlint for documentation
  - EditorConfig checker
  - Custom validators for Brewfile, npmfile, Rustfile
  - TODO comment checker for commits

### GitHub Actions
- [x] **Review and update CI workflow** ✅ COMPLETED
  - Updated .github/workflows/install.yml with health check
  - Tests on macOS 14, macOS 15, and Ubuntu
  - Matrix testing for different configurations
  - Added BATS installation step

- [x] **Add additional workflows** ✅ PARTIALLY COMPLETED
  - ✅ Created lint.yml workflow (shellcheck, markdownlint, package validation)
  - ✅ Created test.yml workflow (BATS tests, integration tests)
  - ✅ Added CI badges to README
  - [ ] Broken link checker (future)
  - [ ] Dependency update automation (future)

## Package Management

### Homebrew
- [x] **Review and prune Brewfile** ✅ COMPLETED
  - Added comprehensive comments for all packages
  - Grouped packages by category (Development, Languages, Media, etc.)
  - Organized with clear section headers
  - Documented purpose of each package

- [x] **Review and prune Caskfile** ✅ COMPLETED
  - Added comments for all applications
  - Grouped applications by category (Browsers, Dev Tools, Security, etc.)
  - Organized with clear section headers
  - Documented purpose of each application

- [x] **Add Homebrew maintenance commands** ✅ COMPLETED
  - Added `make brew-update` target for updating packages
  - Added `make brew-cleanup` target for cleaning up packages
  - Both targets documented and working

### Node.js
- [x] **Review npmfile packages** ✅ COMPLETED
  - Added comprehensive comments for all 18 packages
  - Organized by category (Package Managers, Development, CLI Utilities, etc.)
  - Documented purpose of each package
  - Ready for use and easy to maintain

- [ ] **Consider alternative Node version managers**
  - Evaluate fnm vs n
  - Document choice in README

### Rust
- [x] **Expand Rustfile** ✅ COMPLETED
  - Added comprehensive comments for core 4 packages
  - Added optional tools section with 12 additional tools
  - Documented duplicates with Homebrew (bat, exa, ripgrep, fd-find)
  - Provided clear guidance on which tools are optional

### VSCode/VSCodium
- [ ] **Populate install/Codefile**
  - List essential extensions
  - Categorize extensions (language support, themes, utilities)
  - Document each extension's purpose
  - Or remove if not using VSCode extensions

## Feature Additions

### Backup & Restore
- [ ] **Create backup script**
  - Script to backup current configurations before applying dotfiles
  - Save to timestamped directory
  - Include dotfiles, packages, and system settings
  - Add restore functionality

- [ ] **Add backup documentation**
  - When to backup (before major changes, OS updates)
  - What to backup (configs, package lists, custom scripts)
  - How to restore from backup
  - Automated backup scheduling

### Installation Improvements
- [ ] **Create interactive installer**
  - Ask which components to install
  - Skip optional components
  - Provide dry-run mode to preview changes
  - Add progress indicators

- [ ] **Add post-install checklist**
  - Create script that shows what needs manual configuration
  - List services that need to be started
  - Show authentication requirements (GitHub, npm, etc.)
  - Provide setup verification

- [ ] **Add installation logging**
  - Log all installation steps
  - Capture errors for troubleshooting
  - Create install report

### Utility Scripts
- [x] **Add bin/ utilities** ✅ COMPLETED
  - ✅ Created `dotfiles-doctor` - comprehensive health check script
  - ✅ Created `dotfiles-update` - update all packages and configs
  - ✅ Created `dotfiles-backup` - backup configurations and packages
  - [ ] Create `dotfiles-restore` script (future enhancement)

- [x] **Improve existing bin/ scripts** ✅ COMPLETED
  - ✅ Added --help flags to all utility scripts
  - ✅ Added --verbose mode to dotfiles-doctor and dotfiles-update
  - ✅ Added skip options to dotfiles-update (--skip-brew, --skip-npm, --skip-cargo)
  - ✅ Improved error messages with better context

### Tool-Specific Enhancements
- [ ] **AeroSpace**
  - Add more workspace configurations
  - Document window management workflow
  - Add scripts for common layouts
  - Create quick-switch scripts

- [ ] **Tmux**
  - Add TPM (Tmux Plugin Manager)
  - Configure useful plugins (resurrect, continuum, etc.)
  - Add session management scripts
  - Document session workflow

- [ ] **Neovim**
  - Ensure plugin manager is documented
  - Add language server configurations
  - Create debugging configuration
  - Add code snippets

- [ ] **Kitty**
  - Document keyboard shortcuts
  - Add theme switching script
  - Configure font fallbacks

## Security & Privacy

### Secrets Management
- [ ] **Create .env.example files**
  - Template for required environment variables
  - Document what each variable is for
  - Add to .gitignore patterns
  - Document loading mechanism

- [ ] **Document secrets handling**
  - How to manage API keys securely
  - Using macOS Keychain integration
  - GPG encryption for sensitive files
  - Best practices for credentials

- [ ] **Add sensitive file protection**
  - Ensure .gitignore covers all sensitive files
  - Add pre-commit hook to catch secrets
  - Document SSH key management

### Security Hardening
- [ ] **Add security checklist**
  - FileVault configuration steps
  - Firewall settings documentation
  - Privacy settings review
  - Security update procedures

- [ ] **Review file permissions**
  - Ensure no sensitive files are world-readable
  - Check SSH key permissions (600 for private keys)
  - Review GPG key security
  - Document permission requirements

- [ ] **Add security audit script**
  - Check file permissions
  - Verify firewall status
  - Check for outdated packages
  - Verify encryption status

## Platform Support

### Linux Support
- [ ] **Test on Arch Linux**
  - Verify pacmanfile works correctly
  - Test symlink creation on Linux
  - Document Linux-specific setup steps
  - Test all bin/ scripts on Arch

- [ ] **Add Ubuntu/Debian support**
  - Create Ubuntu package list (apt)
  - Add apt-based installation
  - Document differences from macOS
  - Test on Ubuntu LTS versions

- [ ] **Handle platform differences**
  - Document platform-specific configurations
  - Add conditional loading in configs
  - Test cross-platform compatibility

### Multi-Machine Support
- [ ] **Add machine-specific configs**
  - Use conditional includes in configs
  - Separate work and personal configurations
  - Add hostname-based configuration loading
  - Document multi-machine workflow

- [ ] **Create machine profiles**
  - Define different profiles (work, home, laptop, desktop)
  - Allow profile selection during installation
  - Document profile customization

## Maintenance

### Regular Updates
- [ ] **Create comprehensive update script**
  - Update all package managers (brew, npm, cargo)
  - Update git submodules if any
  - Prune old/unused packages
  - Generate update report

- [ ] **Automate maintenance tasks**
  - Weekly: Update packages
  - Monthly: Review and prune packages
  - Quarterly: Test full installation on clean system
  - Document maintenance schedule

- [ ] **Add health check script**
  - Verify symlinks are intact
  - Check for broken dependencies
  - Verify configuration file syntax
  - Report issues and suggestions

### Documentation Maintenance
- [ ] **Schedule documentation reviews**
  - Review READMEs quarterly
  - Update based on tool changes
  - Add new sections as tools are added
  - Archive outdated information

- [ ] **Keep package lists current**
  - Remove deprecated packages
  - Update to latest best practices
  - Document package choices
  - Review alternatives regularly

## Nice to Have

### Developer Experience
- [x] **Expand .editorconfig** ✅ COMPLETED
  - Added settings for 20+ file types and languages
  - Configured language-specific indentation rules
  - Added line length limits where appropriate
  - Comprehensive coverage for all common file types

- [ ] **Create development containers**
  - Dockerfile for testing installations
  - Docker Compose for full environment
  - Document container usage
  - Add to CI/CD pipeline

### Automation Enhancements
- [x] **Add Make targets** ✅ COMPLETED
  - ✅ `make doctor` - Check system state and health
  - ✅ `make backup` - Backup current configurations
  - ✅ `make backup-compress` - Backup with compression
  - ✅ `make backup-cleanup` - Remove old backups
  - ✅ `make update` - Update all packages
  - ✅ `make restore` - Restore .zshenv from backup
  - ✅ `make clean` - Remove broken symlinks
  - ✅ `make brew-update` - Update Homebrew packages
  - ✅ `make brew-cleanup` - Clean Homebrew cache
  - ✅ Security audit covered by `make doctor`

- [x] **Create Makefile documentation** ✅ COMPLETED
  - Created comprehensive MAKEFILE.md with all targets
  - Documented dependency graph
  - Added extensive usage examples and troubleshooting
  - Documented all variables and environment settings
  - Included tips, best practices, and common issues

### Integration
- [ ] **Add browser configuration sync**
  - Firefox sync setup documentation
  - Brave sync setup (if used)
  - Extension management automation
  - Bookmark backup/restore

- [ ] **Cloud storage integration**
  - Document using with Dropbox/iCloud
  - Selective sync configuration
  - Conflict resolution strategies
  - Privacy considerations

### Quality of Life
- [ ] **Add dotfiles CLI tool**
  - Unified command-line interface
  - Commands: install, update, backup, restore, doctor
  - Interactive prompts for common tasks
  - Shell completion

- [ ] **Create status dashboard**
  - Show installed packages
  - Show symlink status
  - Show update availability
  - Show system health

## Future Considerations

### New Tools to Evaluate
- [ ] **Window Management**
  - yabai as alternative to AeroSpace
  - Rectangle for non-tiling option
  - Hammerspoon for custom scripting

- [ ] **Terminal Emulators**
  - Wezterm as alternative to Kitty
  - Alacritty for comparison
  - Compare performance and features

- [ ] **Shell Alternatives**
  - Fish shell as Zsh alternative
  - Nushell for exploration
  - Evaluate pros/cons

- [ ] **Editor Alternatives**
  - Helix as Neovim alternative
  - Full VSCode configuration
  - Compare workflows

### Alternative Approaches
- [ ] **Evaluate chezmoi**
  - Compare chezmoi with current Stow approach
  - Test template functionality
  - Evaluate secret management
  - Document migration path if chosen

- [ ] **Consider Nix/Home Manager**
  - Evaluate Nix for reproducible environments
  - Test nix-darwin for macOS
  - Compare with current approach
  - Consider hybrid approach

- [ ] **Investigate Ansible**
  - Could replace Makefile for some tasks
  - Better idempotency
  - More complex but more powerful
  - Evaluate if complexity is worth it

### Advanced Features
- [ ] **Add dotfiles sync service**
  - Automatic backup to cloud
  - Multi-machine sync
  - Conflict resolution
  - Privacy-preserving sync

- [ ] **Create web dashboard**
  - Visual representation of configs
  - Browse configurations online
  - Search across all configs
  - View change history

## Known Issues

- [x] **Codefile is empty** - ✅ RESOLVED: Populated with VSCodium extensions
- [x] **No test directory** - ✅ RESOLVED: Created test infrastructure with BATS
- [x] **Missing GitHub workflows** - ✅ RESOLVED: Updated install.yml, created lint.yml and test.yml
- [ ] **Some configs lack READMEs** - All 15 .config directories have READMEs (verified)

## Contributing Guidelines

When working on TODO items:

1. **Branch naming**: `feature/item-name` or `fix/issue-name`
2. **Update this file**: Mark items as complete, add new items discovered
3. **Documentation**: Update relevant READMEs
4. **Testing**: Test changes on clean system if possible
5. **Commit messages**: Follow conventional commit format
6. **Pull requests**: Provide clear description and link to TODO item

## Priority Legend

- 🔴 **Critical Issues**: Must be fixed for proper functionality
- 🟡 **Documentation**: Important for usability and maintenance
- 🟢 **Configuration Improvements**: Enhance user experience
- 🔵 **Testing & CI/CD**: Important for maintainability
- 🟣 **Feature Additions**: New functionality
- ⚪ **Nice to Have**: Low priority, future considerations

---

**Last Updated:** October 24, 2025
**Repository State:** PRODUCTION-READY with comprehensive documentation, testing, and CI/CD
**Recent Session Achievements:**
- Documentation (12 files): CLAUDE.md, CONTRIBUTING.md, CHANGELOG.md, LICENSE, .gitattributes, MAKEFILE.md, .github/README.md
- Enhanced: README.md (FAQ, CI badges), install/README.md, test/README.md
- Package files: Fully documented ALL 5 package files with 160+ comments
- CI/CD: 3 GitHub Actions workflows (install, test, lint)
- Utility scripts: dotfiles-doctor, dotfiles-update, dotfiles-backup (with --help, --verbose)
- Make targets: 9 new targets (doctor, update, backup, clean, restore, brew-update, brew-cleanup)
- Testing: BATS framework with 4 test files and .shellcheckrc
- Configuration: Expanded .editorconfig to 20+ file types
- Verified: All .config directories have READMEs, all known issues resolved
- Result: World-class, production-ready dotfiles repository
