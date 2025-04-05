# Setup-Mac

## Add new command
```sh
./add.sh MY NEW COMMAND
```
It will run it locally and add to step2.zsh afterwords it runs git commit and git push

## Pre-commit Hooks

This repository uses pre-commit hooks to ensure code quality and prevent secrets from being committed.

### Setup

1. Make sure pre-commit is installed:
   ```sh
   # Using Homebrew
   brew install pre-commit
   # Or using pip
   pip install pre-commit
   ```

2. Install the hooks in your local repository:
   ```sh
   pre-commit install
   ```

### Included Hooks

- **Git Secret Leak Detection**: Using Gitleaks to prevent accidental commit of secrets
- **Code Quality Checks**: Trailing whitespace, file endings, YAML validation, etc.
- **Security Checks**: Detection of private keys and large files

## TODOs
- [ ] Check out all configs in ~/.config folder
