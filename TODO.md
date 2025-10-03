# TODO List

Organized list of improvements, fixes, and future enhancements for the dotfiles repository.

## Critical Issues

### Directory Structure Mismatches
- [ ] **Fix Makefile directory references**
  - Makefile references `runcom` directory that doesn't exist
  - Makefile references `config` directory but uses `.config` instead
  - Update Makefile to use correct directory names or create missing directories
  
- [ ] **Create missing runcom directory**
  - Decision needed: Use `runcom/` or continue with root-level files?
  - If using `runcom/`, move `.zshenv` and other shell startup files there
  - Update symlink logic in Makefile accordingly

### Missing Files
- [ ] **Add duti configuration file**
  - Makefile references `install/duti` but file doesn't exist
  - Create `install/duti` with default application associations
  - Document duti usage in install/README.md

- [ ] **Populate Codefile**
  - `install/Codefile` is currently empty
  - Add VS Code / VSCodium extensions list
  - Or remove if not using VSCode extensions

- [ ] **Create missing scripts**
  - Makefile references bin scripts: `is-supported`, `is-macos`, `is-arch`, `is-arm64`
  - These may exist but aren't visible - verify location
  - Document all scripts in .local/bin/

## Documentation

### Missing READMEs
- [ ] **Create .local/bin/README.md**
  - Document all utility scripts
  - Explain what each script does
  - Add usage examples

- [ ] **Create .github/README.md**
  - Explain CI/CD workflow
  - Document Dependabot configuration
  - Add badge links for workflow status

- [ ] **Add root-level documentation files**
  - [ ] CONTRIBUTING.md - Guidelines for contributions
  - [ ] CHANGELOG.md - Track major changes
  - [ ] LICENSE - Add license information

### Improve Existing Documentation
- [ ] **Update .config/nvim/README.md**
  - Currently exists but may need updating
  - Document plugin list and keybindings
  - Add installation troubleshooting

- [ ] **Enhance install/README.md**
  - Add troubleshooting section for common install issues
  - Document how to restore from backup
  - Add platform-specific quirks

## Configuration Improvements

### Shell Configuration
- [ ] **Organize Zsh configuration**
  - Split .zshrc into modular files (aliases, functions, plugins)
  - Create separate files for different environments (work, personal)
  - Add better comments explaining each section

- [ ] **Improve .aliases organization**
  - Categorize aliases better
  - Remove unused/outdated aliases
  - Add more macOS-specific utilities

### macOS Configuration
- [ ] **Test and update defaults.sh**
  - Verify all settings work on latest macOS
  - Add comments explaining each setting
  - Group settings by category

- [ ] **Test and update dock.sh**
  - Verify application paths are correct
  - Make dock applications configurable
  - Add option for different dock layouts

### Git Configuration
- [ ] **Add .gitattributes**
  - Define line ending behavior
  - Add diff patterns for common file types
  
- [ ] **Enhance .gitconfig**
  - Add more useful aliases
  - Configure GPG signing
  - Add conditional includes for work/personal

## Testing & CI/CD

### Testing Infrastructure
- [ ] **Create test directory**
  - Makefile references `bats test` but no test directory exists
  - Set up BATS testing framework
  - Write tests for installation process
  - Write tests for symlink creation

- [ ] **Add linting**
  - Add shellcheck for bash scripts
  - Add yamllint for YAML files
  - Add markdownlint for documentation

### GitHub Actions
- [ ] **Update CI workflow**
  - Verify .github/workflows/install.yml is current
  - Test on multiple macOS versions
  - Add Linux testing if supporting Linux
  - Add matrix testing for different configurations

- [ ] **Add additional workflows**
  - [ ] Lint workflow (shellcheck, yamllint, markdownlint)
  - [ ] Documentation validation
  - [ ] Broken link checker

## Package Management

### Homebrew
- [ ] **Review and prune Brewfile**
  - Remove unused packages
  - Add comments explaining why each package is needed
  - Group packages by category

- [ ] **Review and prune Caskfile**
  - Remove unused applications
  - Verify all applications are still maintained
  - Consider alternatives for outdated apps

### Node.js
- [ ] **Review npmfile packages**
  - Remove deprecated packages
  - Update to modern alternatives where applicable
  - Consider pnpm-only or yarn-only workflow

### Rust
- [ ] **Expand Rustfile**
  - Add more useful Rust CLI tools
  - Consider: bat, exa, ripgrep, fd-find, hyperfine, tokei
  - Document why each tool is chosen

## Feature Additions

### Backup & Restore
- [ ] **Create backup script**
  - Script to backup current configurations before applying dotfiles
  - Save to timestamped directory
  - Add restore functionality

- [ ] **Document backup process**
  - When to backup
  - What to backup
  - How to restore

### Installation
- [ ] **Create interactive installer**
  - Ask which components to install
  - Skip optional components
  - Provide dry-run mode

- [ ] **Add post-install checklist**
  - Create script that shows what needs manual configuration
  - List services that need to be started
  - Show authentication requirements

### Tool-Specific
- [ ] **AeroSpace**
  - Add more workspace configurations
  - Document window management workflow
  - Add scripts for common layouts

- [ ] **Tmux**
  - Add TPM (Tmux Plugin Manager)
  - Configure useful plugins
  - Add session management scripts

- [ ] **Neovim**
  - Document plugin management
  - Add language server configurations
  - Create debugging configuration

## Security & Privacy

### Secrets Management
- [ ] **Create .env.example files**
  - Template for required environment variables
  - Document what each variable is for
  - Add to .gitignore

- [ ] **Document secrets handling**
  - How to manage API keys
  - Using macOS Keychain
  - GPG encryption for sensitive files

### Security Hardening
- [ ] **Add security checklist**
  - FileVault configuration
  - Firewall settings
  - Privacy settings review

- [ ] **Review file permissions**
  - Ensure no sensitive files are world-readable
  - Check SSH key permissions
  - Review GPG key security

## Platform Support

### Linux Support
- [ ] **Test on Arch Linux**
  - Verify pacmanfile works
  - Test symlink creation
  - Document Linux-specific setup

- [ ] **Add Ubuntu support**
  - Create Ubuntu package list
  - Add apt-based installation
  - Document differences from macOS

### Multi-Machine Support
- [ ] **Add machine-specific configs**
  - Use conditional includes in configs
  - Separate work and personal configurations
  - Add hostname-based configuration loading

## Maintenance

### Regular Updates
- [ ] **Create update script**
  - Update all package managers
  - Update git submodules if any
  - Prune old packages

- [ ] **Schedule maintenance tasks**
  - Weekly: Update packages
  - Monthly: Review and prune packages
  - Quarterly: Test full installation on clean system

### Documentation Maintenance
- [ ] **Keep READMEs current**
  - Review quarterly
  - Update based on changes
  - Add new sections as tools are added

## Nice to Have

### Developer Experience
- [ ] **Add editorconfig for more file types**
  - Expand .editorconfig coverage
  - Add settings for all used languages

- [ ] **Create development containers**
  - Dockerfile for testing installations
  - Docker Compose for full environment

### Automation
- [ ] **Add more Make targets**
  - `make doctor` - Check system state
  - `make backup` - Backup current configs
  - `make restore` - Restore from backup
  - `make clean` - Remove broken symlinks

### Integration
- [ ] **Add browser sync**
  - Firefox sync configuration
  - Brave sync setup
  - Extension management

- [ ] **Cloud storage integration**
  - Document using with Dropbox/iCloud
  - Selective sync configuration

## Future Considerations

### New Tools to Evaluate
- [ ] **Window Management**
  - yabai as alternative to AeroSpace
  - Rectangle for non-tiling option

- [ ] **Terminal**
  - Wezterm as alternative to Kitty
  - Alacritty for comparison

- [ ] **Shell**
  - Fish shell as alternative
  - Nushell for exploration

- [ ] **Editor**
  - Helix as alternative to Neovim
  - VSCode full configuration

### Alternative Approaches
- [ ] **Consider chezmoi**
  - Evaluate chezmoi for dotfile management
  - Compare with current stow approach

- [ ] **Consider Nix**
  - Evaluate Nix for reproducible environments
  - Nix-darwin for macOS

---

## Priority Legend
- **Critical Issues**: Must be fixed for proper functionality
- **Documentation**: Should be completed for usability
- **Configuration Improvements**: Nice to have for better experience
- **Testing & CI/CD**: Important for maintainability
- **Feature Additions**: Enhance functionality
- **Nice to Have**: Can be done when time permits

## Contributing
When working on TODO items:
1. Create a branch for the feature/fix
2. Update this TODO.md to mark items as complete
3. Add any new TODOs discovered during work
4. Submit PR with clear description
5. Update relevant documentation
