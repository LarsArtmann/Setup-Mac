# Development Environment Setup Guide

This guide walks you through setting up a complete development environment on macOS using Nix Darwin and Home Manager.

## Prerequisites

- macOS (Apple Silicon or Intel)
- Xcode Command Line Tools: `xcode-select --install`
- Administrative access to install system-level tools

## Quick Start

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd Setup-Mac
   ```

2. **Install Nix:**
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```

3. **Apply the configuration:**
   ```bash
   cd dotfiles/nix
   darwin-rebuild switch --flake .#Lars-MacBook-Air
   ```

4. **Restart your terminal** to load all new environment variables and PATH changes.

## What Gets Installed

### Core Development Tools

- **Version Control:** Git, Git LFS, Git Town, GitHub CLI, Lazygit
- **Build Systems:** Just (task runner), Gradle, Maven, Devenv
- **Languages & Runtimes:**
  - Go with templ (HTML templating)
  - Node.js with Bun and pnpm
  - Java (JDK 21) with Kotlin
  - .NET Core SDK 8.0
  - Ruby
  - Rust (via rustup)
  - Python utilities (uv)

### Cloud & Infrastructure

- **AWS:** CLI v2, IAM Authenticator, AWS Vault
- **Google Cloud:** Full SDK
- **Kubernetes:** kubectl, Helm, k9s, Cilium CLI, k8sgpt, Helmfile
- **Infrastructure as Code:** Terraform, Colmena (NixOS deployment)
- **Other:** Stripe CLI

### Command Line Utilities

- **File Operations:** bat (better cat), fd (better find), ripgrep (rg), tree, ncdu
- **Text Processing:** jq, yq-go, glow (markdown renderer)
- **System Tools:** htop, hyperfine, nmap, fzf (fuzzy finder)
- **Security:** age (encryption), gitleaks (secret scanning), mitmproxy
- **Media:** ffmpeg, imagemagick, exiftool

### Applications (via Homebrew)

- **Productivity:** Raycast, Notion, Obsidian, Postman
- **Security:** Little Snitch, Lulu, Secretive, MacPass
- **Development:** JetBrains Toolbox, Sublime Text
- **Media:** Spotify, OBS Studio, OpenAudible
- **Communication:** Franz, WhatsApp, Legcord (Discord)
- **Utilities:** Google Drive, CloudFlare Warp, DeepL

### macOS App Store Apps

- AusweisApp, Color Picker, Numbers, Outbank
- Pastebot, Photo Anonymizator, Quick Camera
- TripMode, WireGuard, Dice

## Configuration Structure

```
dotfiles/nix/
├── flake.nix           # Main flake configuration
├── core.nix            # Core Nix settings
├── system.nix          # macOS system preferences
├── environment.nix     # Packages and environment variables
├── programs.nix        # Program-specific configurations
├── homebrew.nix        # Homebrew packages and casks
├── networking.nix      # Network and DNS settings
├── users.nix           # User account settings
└── home.nix            # Home Manager configuration
```

## Customization

### Adding New Packages

**Nix packages** (preferred for CLI tools):
Edit `environment.nix` and add to the appropriate section:
```nix
systemPackages = with pkgs; [
  # Add your package here
  your-package
];
```

**Homebrew packages** (for GUI apps or packages not in nixpkgs):
Edit `homebrew.nix`:
```nix
brews = [
  "your-cli-tool"
];

casks = [
  "your-gui-app"
];
```

### Modifying Shell Configuration

Shell aliases are defined in `environment.nix`:
```nix
shellAliases = {
  your-alias = "your-command";
};
```

### Environment Variables

Add custom environment variables in `environment.nix`:
```nix
variables = {
  YOUR_VAR = "your-value";
};
```

## Development Workflows

### Go Development

The setup includes:
- Go compiler and standard tools
- templ for type-safe HTML templates
- go-tools (staticcheck, etc.)
- sqlc for type-safe SQL

Example workflow:
```bash
# Create new project
mkdir my-go-project && cd my-go-project
go mod init my-project

# Generate HTML templates with templ
templ generate

# Run with live reload (if using air)
air
```

### JavaScript/TypeScript Development

Includes Node.js, Bun, and pnpm:
```bash
# Use Bun for new projects
bun create next-app my-app
cd my-app
bun dev

# Or use pnpm for existing projects
pnpm install
pnpm dev
```

### Kubernetes Development

All essential tools are included:
```bash
# View cluster status
k9s

# Deploy with Helm
helm install my-app ./charts/my-app

# Use Cilium CLI for networking
cilium status
```

## Maintenance

### Updating Packages

```bash
cd dotfiles/nix

# Update flake inputs
nix flake update

# Apply updates
darwin-rebuild switch --flake .#Lars-MacBook-Air
```

### Cleaning Up

```bash
# Clean old generations
nix-collect-garbage -d

# Clean Homebrew
brew cleanup
```

### Troubleshooting

See `docs/troubleshooting/` for common issues and solutions.

## Security Considerations

- Gitleaks automatically scans for secrets in repositories
- Little Snitch and Lulu provide network monitoring and firewall protection
- Secretive manages SSH keys securely in the Secure Enclave
- Age provides modern encryption for sensitive files

## Performance Tips

- Use `hyperfine` for benchmarking commands
- `ncdu` for disk usage analysis
- `htop` for system monitoring
- Tools are configured with performance optimizations where applicable

## Support

For issues specific to this configuration, check:
1. `docs/troubleshooting/` directory
2. Nix Darwin documentation: https://daiderd.com/nix-darwin/
3. Home Manager manual: https://nix-community.github.io/home-manager/

## Contributing

When adding new tools or modifying configurations:
1. Test changes with `nix flake check`
2. Document any new tools or workflows
3. Update this guide if the setup process changes
4. Consider security and performance implications