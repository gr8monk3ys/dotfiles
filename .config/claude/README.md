# Claude Code Integration

This directory contains references and integration notes for [Claude Code](https://claude.ai/code), Anthropic's AI assistant for software development.

## Overview

Claude Code is an AI-powered CLI tool that helps with:

- Code generation and modification
- Debugging and error analysis
- Documentation writing
- Code review and refactoring
- Project exploration and understanding

## Configuration Repository

My Claude Code skills, workflows, and custom configurations are maintained in a separate repository:

**Repository:** [https://github.com/gr8monk3ys/lorenzos-claude-code](https://github.com/gr8monk3ys/lorenzos-claude-code)

This includes:

- Custom skills and workflows
- Project-specific CLAUDE.md files
- Best practices and patterns
- Custom prompts and templates

## Installation

```bash
# Install Claude Code CLI
npm install -g @anthropic-ai/claude-code

# Or via Homebrew (if available)
brew install claude-code
```

## Shell Integration

Aliases are configured in `~/.config/zsh/aliases.zsh`:

```bash
alias cc='claude'
```

## Project Configuration

Each project can have a `CLAUDE.md` file at the root that provides context to Claude about:

- Project structure
- Coding conventions
- Important files and patterns
- Development workflows

Example structure:

```markdown
# CLAUDE.md

## Project Overview
Brief description of the project...

## Key Files
- `src/main.ts` - Entry point
- `src/config/` - Configuration files

## Conventions
- Use TypeScript strict mode
- Follow ESLint rules
- Test with Jest
```

## Usage Tips

### Starting a Session

```bash
# In project directory
claude

# Or with specific task
claude "fix the failing tests"
```

### Effective Prompts

- Be specific about what you want
- Reference file paths when relevant
- Describe the expected behavior
- Mention constraints or preferences

### Best Practices

1. **Keep CLAUDE.md updated** - Good context improves responses
2. **Review changes** - Always review AI-generated code
3. **Iterate** - Refine requests based on results
4. **Version control** - Commit before and after AI changes

## Integration with Dotfiles

This dotfiles repo includes a comprehensive `CLAUDE.md` at the root that helps Claude understand:

- Repository structure
- Configuration patterns
- XDG conventions used
- Makefile targets

## Resources

- [Claude Code Documentation](https://docs.anthropic.com/claude-code)
- [My Claude Code Config](https://github.com/gr8monk3ys/lorenzos-claude-code)
- [Anthropic API](https://docs.anthropic.com/api)
