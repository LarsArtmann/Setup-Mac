# Pre-commit hooks configuration (Cross-Platform)
# Migrated from dotfiles/.pre-commit-config.yaml
_: {
  # Pre-commit hooks for configuration validation
  # Ensures configuration errors are caught early in development workflow
  home.file.".config/pre-commit/config.yaml" = {
    text = ''
      # Pre-commit hooks for configuration validation
      # Ensures configuration errors are caught early in development workflow

      repos:
        # Configuration validation hooks
        - repo: local
          hooks:
            # Quick Nix configuration validation on Nix file changes
            - id: nix-config-validate
              name: Nix Configuration Validation
              entry: ./scripts/config-validate.sh --quick nix
              language: script
              files: \.nix$
              pass_filenames: false
              always_run: false

            # Shell configuration validation on shell file changes
            - id: shell-config-validate
              name: Shell Configuration Validation
              entry: ./scripts/config-validate.sh --quick shell
              language: script
              files: \.(fish|zsh|bash|sh)$|^\.zshrc$|^\.bashrc$|^\.profile$
              pass_filenames: false
              always_run: false

            # Dependency conflict check on package-related changes
            - id: dependency-conflict-check
              name: Dependency Conflict Check
              entry: ./scripts/config-validate.sh --quick deps
              language: script
              files: ^(flake\.nix|homebrew\.nix|environment\.nix|programs\.nix)$
              pass_filenames: false
              always_run: false

        # Standard formatting and linting hooks
        - repo: https://github.com/pre-commit/pre-commit-hooks
          rev: v4.4.0
          hooks:
            # Basic file checks
            - id: check-added-large-files
              args: ['--maxkb=1000']
            - id: check-case-conflict
            - id: check-executables-have-shebangs
            - id: check-merge-conflict
            - id: check-symlinks
            - id: check-toml
            - id: check-yaml
              args: ['--allow-multiple-documents']
            - id: check-json

            # File content checks
            - id: detect-private-key
            - id: end-of-file-fixer
            - id: trailing-whitespace
              args: ['--markdown-linebreak-ext=md']

            # Mixed line endings
            - id: mixed-line-ending
              args: ['--fix=lf']

        # Nix-specific formatting
        - repo: https://github.com/nix-community/nixpkgs-fmt
          rev: v1.3.0
          hooks:
            - id: nixpkgs-fmt

        # Shell script linting
        - repo: https://github.com/koalaman/shellcheck-precommit
          rev: v0.9.0
          hooks:
            - id: shellcheck
              args: ['--severity=warning']

        # Markdown linting
        - repo: https://github.com/igorshubovych/markdownlint-cli
          rev: v0.35.0
          hooks:
            - id: markdownlint
              args: ['--fix', '--disable', 'MD013', 'MD033', 'MD041']

      # Global settings
      default_stages: [commit]
      fail_fast: false
    '';
  };
}
