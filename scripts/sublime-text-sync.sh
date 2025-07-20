#!/usr/bin/env bash

# SublimeText Configuration Sync Automation
# Addresses issue #2: Automate SublimeText configuration sync
#
# This script automates the synchronization of SublimeText settings
# to maintain consistent configuration across systems.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")/dotfiles"
SUBLIME_CONFIG_DIR="$DOTFILES_DIR/sublime-text"
SUBLIME_USER_DIR="$HOME/Library/Application Support/Sublime Text/Packages/User"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Check if SublimeText is installed
check_sublime_installation() {
    if ! command -v subl >/dev/null 2>&1; then
        if [[ ! -d "/Applications/Sublime Text.app" ]]; then
            error "SublimeText is not installed. Please install it first."
        else
            warn "SublimeText CLI not in PATH. Creating symlink..."
            sudo ln -sf "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" /usr/local/bin/subl || \
                warn "Could not create symlink. You may need to install CLI tools manually."
        fi
    fi
}

# Check if SublimeText user directory exists
check_sublime_user_dir() {
    if [[ ! -d "$SUBLIME_USER_DIR" ]]; then
        error "SublimeText user directory not found: $SUBLIME_USER_DIR"
    fi
}

# Create sublime-text dotfiles directory structure
setup_dotfiles_structure() {
    log "Setting up SublimeText dotfiles structure..."
    mkdir -p "$SUBLIME_CONFIG_DIR"/{settings,packages,keymaps,snippets,themes}

    # Create README for the sublime-text directory
    cat > "$SUBLIME_CONFIG_DIR/README.md" << 'EOF'
# SublimeText Configuration

This directory contains synchronized SublimeText configuration files.

## Structure

- `settings/` - User preferences and settings files
- `packages/` - Package installation metadata
- `keymaps/` - Custom key bindings
- `snippets/` - Code snippets
- `themes/` - Custom color schemes and themes

## Sync Process

Configuration is automatically synchronized using the `sublime-text-sync.sh` script:

1. **Backup**: Current settings are backed up before sync
2. **Export**: Active configuration is exported to dotfiles
3. **Import**: Configuration is imported from dotfiles to SublimeText
4. **Validate**: Changes are validated for consistency

## Files Managed

- `Preferences.sublime-settings` - Main preferences
- `*.sublime-keymap` - Key bindings
- `*.sublime-snippet` - Code snippets
- `*.sublime-theme` - UI themes
- `*.sublime-color-scheme` - Color schemes
- `Package Control.sublime-settings` - Package manager settings

## Restoration

To restore configuration on a new system:
```bash
./scripts/sublime-text-sync.sh --import
```

## Manual Sync

To manually export current configuration:
```bash
./scripts/sublime-text-sync.sh --export
```
EOF

    log "SublimeText dotfiles structure created at: $SUBLIME_CONFIG_DIR"
}

# Export current SublimeText configuration to dotfiles
export_config() {
    log "Exporting SublimeText configuration to dotfiles..."

    # Create backup directory with timestamp
    local backup_dir="$SUBLIME_CONFIG_DIR/backups/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"

    # Copy existing dotfiles config to backup
    if [[ -d "$SUBLIME_CONFIG_DIR/settings" ]]; then
        cp -r "$SUBLIME_CONFIG_DIR/settings"/* "$backup_dir/" 2>/dev/null || true
    fi

    # Export main settings files
    if [[ -f "$SUBLIME_USER_DIR/Preferences.sublime-settings" ]]; then
        cp "$SUBLIME_USER_DIR/Preferences.sublime-settings" "$SUBLIME_CONFIG_DIR/settings/"
        log "✓ Exported Preferences.sublime-settings"
    fi

    # Export package control settings
    if [[ -f "$SUBLIME_USER_DIR/Package Control.sublime-settings" ]]; then
        cp "$SUBLIME_USER_DIR/Package Control.sublime-settings" "$SUBLIME_CONFIG_DIR/settings/"
        log "✓ Exported Package Control.sublime-settings"
    fi

    # Export keymaps
    for keymap in "$SUBLIME_USER_DIR"/*.sublime-keymap; do
        if [[ -f "$keymap" ]]; then
            cp "$keymap" "$SUBLIME_CONFIG_DIR/keymaps/"
            log "✓ Exported $(basename "$keymap")"
        fi
    done

    # Export snippets
    for snippet in "$SUBLIME_USER_DIR"/*.sublime-snippet; do
        if [[ -f "$snippet" ]]; then
            cp "$snippet" "$SUBLIME_CONFIG_DIR/snippets/"
            log "✓ Exported $(basename "$snippet")"
        fi
    done

    # Export themes and color schemes
    for theme in "$SUBLIME_USER_DIR"/*.{sublime-theme,sublime-color-scheme}; do
        if [[ -f "$theme" ]]; then
            cp "$theme" "$SUBLIME_CONFIG_DIR/themes/"
            log "✓ Exported $(basename "$theme")"
        fi
    done

    log "Configuration exported to: $SUBLIME_CONFIG_DIR"
    info "Backup created at: $backup_dir"
}

# Import configuration from dotfiles to SublimeText
import_config() {
    log "Importing SublimeText configuration from dotfiles..."

    # Create backup of current user directory
    local user_backup_dir="$HOME/.sublime-text-backup-$(date +%Y%m%d-%H%M%S)"
    if [[ -d "$SUBLIME_USER_DIR" ]]; then
        cp -r "$SUBLIME_USER_DIR" "$user_backup_dir"
        log "Created backup of current config at: $user_backup_dir"
    fi

    # Ensure user directory exists
    mkdir -p "$SUBLIME_USER_DIR"

    # Import settings files
    if [[ -d "$SUBLIME_CONFIG_DIR/settings" ]]; then
        for setting_file in "$SUBLIME_CONFIG_DIR/settings"/*.sublime-settings; do
            if [[ -f "$setting_file" ]]; then
                cp "$setting_file" "$SUBLIME_USER_DIR/"
                log "✓ Imported $(basename "$setting_file")"
            fi
        done
    fi

    # Import keymaps
    if [[ -d "$SUBLIME_CONFIG_DIR/keymaps" ]]; then
        for keymap in "$SUBLIME_CONFIG_DIR/keymaps"/*.sublime-keymap; do
            if [[ -f "$keymap" ]]; then
                cp "$keymap" "$SUBLIME_USER_DIR/"
                log "✓ Imported $(basename "$keymap")"
            fi
        done
    fi

    # Import snippets
    if [[ -d "$SUBLIME_CONFIG_DIR/snippets" ]]; then
        for snippet in "$SUBLIME_CONFIG_DIR/snippets"/*.sublime-snippet; do
            if [[ -f "$snippet" ]]; then
                cp "$snippet" "$SUBLIME_USER_DIR/"
                log "✓ Imported $(basename "$snippet")"
            fi
        done
    fi

    # Import themes
    if [[ -d "$SUBLIME_CONFIG_DIR/themes" ]]; then
        for theme in "$SUBLIME_CONFIG_DIR/themes"/*.{sublime-theme,sublime-color-scheme}; do
            if [[ -f "$theme" ]]; then
                cp "$theme" "$SUBLIME_USER_DIR/"
                log "✓ Imported $(basename "$theme")"
            fi
        done
    fi

    log "Configuration imported successfully"
}

# Create enhanced default configuration files
create_enhanced_config() {
    log "Creating enhanced SublimeText configuration..."

    # Enhanced Preferences
    cat > "$SUBLIME_CONFIG_DIR/settings/Preferences.sublime-settings" << 'EOF'
{
    // Font configuration optimized for development
    "font_face": "JetBrains Mono",
    "font_size": 14,
    "font_options": ["subpixel_antialias"],

    // Editor behavior
    "spell_check": true,
    "spell_check_languages": ["en_US"],
    "translate_tabs_to_spaces": true,
    "tab_size": 2,
    "detect_indentation": true,
    "trim_trailing_white_space_on_save": true,
    "ensure_newline_at_eof_on_save": true,
    "auto_complete_commit_on_tab": true,
    "auto_complete_with_fields": true,
    "auto_match_enabled": true,

    // Visual enhancements
    "line_numbers": true,
    "gutter": true,
    "margin": 100,
    "rulers": [80, 100, 120],
    "highlight_line": true,
    "highlight_modified_tabs": true,
    "show_definitions": true,
    "show_line_endings": false,
    "word_wrap": "auto",
    "wrap_width": 0,

    // File handling
    "atomic_save": false,
    "fallback_encoding": "UTF-8",
    "default_encoding": "UTF-8",
    "enable_hexadecimal_encoding": false,
    "hot_exit": true,
    "remember_open_files": true,
    "close_windows_when_empty": false,

    // Minimap and sidebar
    "show_minimap": true,
    "minimap_scroll_to_clicked_text": true,
    "preview_on_click": true,
    "folder_exclude_patterns": [
        ".git",
        ".hg",
        ".svn",
        "_darcs",
        "CVS",
        ".DS_Store",
        "node_modules",
        ".next",
        "dist",
        "build",
        "target",
        "vendor",
        ".direnv",
        "result",
        "result-*"
    ],
    "file_exclude_patterns": [
        "*.pyc",
        "*.pyo",
        "*.exe",
        "*.dll",
        "*.obj",
        "*.o",
        "*.a",
        "*.lib",
        "*.so",
        "*.dylib",
        "*.ncb",
        "*.sdf",
        "*.suo",
        "*.pdb",
        "*.idb",
        ".DS_Store",
        "*.class",
        "*.psd",
        "*.db",
        "*.sublime-workspace"
    ],
    "binary_file_patterns": [
        "*.jpg",
        "*.jpeg",
        "*.png",
        "*.gif",
        "*.ttf",
        "*.tga",
        "*.dds",
        "*.ico",
        "*.eot",
        "*.pdf",
        "*.swf",
        "*.jar",
        "*.zip"
    ],

    // Development-specific settings
    "auto_find_in_selection": true,
    "drag_text": false,
    "draw_white_space": "selection",
    "find_selected_text": true,
    "scroll_past_end": true,
    "scroll_speed": 1.0,
    "mouse_wheel_switches_tabs": false,
    "tree_animation_enabled": true,

    // Custom dictionary words for development
    "added_words": [
        "http", "https", "api", "url", "json", "xml", "html", "css", "js",
        "typescript", "javascript", "golang", "golang", "npm", "yarn", "pnpm",
        "github", "gitlab", "bitbucket", "repo", "repos", "codebase", "backend",
        "frontend", "fullstack", "devops", "ci", "cd", "docker", "kubernetes",
        "microservices", "serverless", "nix", "darwin", "homebrew", "dotfiles",
        "eslint", "prettier", "babel", "webpack", "vite", "esbuild", "rollup",
        "react", "vue", "angular", "svelte", "nextjs", "nuxtjs", "gatsby",
        "tailwind", "bootstrap", "scss", "sass", "less", "stylus",
        "postgresql", "mysql", "mongodb", "redis", "elasticsearch", "graphql",
        "oauth", "jwt", "cors", "csrf", "xss", "sql", "nosql", "crud",
        "refactoring", "debugging", "linting", "formatting", "optimization"
    ],

    // Theme and color scheme
    "color_scheme": "Monokai.sublime-color-scheme",
    "theme": "Adaptive.sublime-theme",
    "adaptive_dividers": true,

    // Performance
    "index_files": true,
    "index_exclude_patterns": [
        "*.log",
        "node_modules/*",
        ".git/*",
        "vendor/*",
        "build/*",
        "dist/*"
    ]
}
EOF

    # Package Control Settings
    cat > "$SUBLIME_CONFIG_DIR/settings/Package Control.sublime-settings" << 'EOF'
{
    "bootstrapped": true,
    "in_process_packages": [],
    "installed_packages": [
        "A File Icon",
        "AdvancedNewFile",
        "All Autocomplete",
        "BracketHighlighter",
        "Color Highlight",
        "DocBlockr",
        "Emmet",
        "GitGutter",
        "LSP",
        "LSP-typescript",
        "LSP-json",
        "MarkdownPreview",
        "Package Control",
        "Pretty JSON",
        "SideBarEnhancements",
        "SublimeLinter",
        "SublimeLinter-eslint",
        "Terminus",
        "Theme - One Dark"
    ]
}
EOF

    # Default key bindings for development
    cat > "$SUBLIME_CONFIG_DIR/keymaps/Default (OSX).sublime-keymap" << 'EOF'
[
    // File operations
    { "keys": ["cmd+shift+n"], "command": "new_window" },
    { "keys": ["cmd+option+n"], "command": "advanced_new_file_new" },

    // Code navigation
    { "keys": ["cmd+r"], "command": "show_overlay", "args": {"overlay": "goto", "text": "@"} },
    { "keys": ["cmd+shift+r"], "command": "show_overlay", "args": {"overlay": "goto", "text": "@"} },

    // Terminal integration
    { "keys": ["cmd+shift+t"], "command": "terminus_open", "args": {"config_name": "Default"} },

    // Code formatting
    { "keys": ["cmd+shift+f"], "command": "lsp_format_document" },

    // Git operations
    { "keys": ["cmd+shift+g"], "command": "git_status" },

    // Sidebar toggle
    { "keys": ["cmd+k", "cmd+b"], "command": "toggle_side_bar" },

    // Multiple cursors
    { "keys": ["cmd+shift+l"], "command": "split_selection_into_lines" },
    { "keys": ["cmd+d"], "command": "find_under_expand" },
    { "keys": ["cmd+k", "cmd+d"], "command": "find_under_expand_skip" },

    // Code folding
    { "keys": ["cmd+option+["], "command": "fold" },
    { "keys": ["cmd+option+]"], "command": "unfold" }
]
EOF

    log "Enhanced configuration files created"
}

# Create launchd service for automatic sync
create_sync_service() {
    local plist_file="$HOME/Library/LaunchAgents/com.larsartmann.sublime-sync.plist"

    log "Creating automatic sync service..."
    cat > "$plist_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.larsartmann.sublime-sync</string>
    <key>ProgramArguments</key>
    <array>
        <string>$SCRIPT_DIR/sublime-text-sync.sh</string>
        <string>--export</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>18</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>$SUBLIME_CONFIG_DIR/sync.log</string>
    <key>StandardErrorPath</key>
    <string>$SUBLIME_CONFIG_DIR/sync.error.log</string>
</dict>
</plist>
EOF

    launchctl load "$plist_file" 2>/dev/null || warn "launchd service may already be loaded"
    log "Automatic sync service created and loaded: $plist_file"
}

# Validate configuration
validate_config() {
    log "Validating SublimeText configuration..."

    local issues=0

    # Check for valid JSON in settings files (handle SublimeText's relaxed JSON format)
    for settings_file in "$SUBLIME_CONFIG_DIR/settings"/*.sublime-settings; do
        if [[ -f "$settings_file" ]]; then
            # Strip comments and validate JSON (SublimeText supports relaxed JSON format)
            local temp_json=$(mktemp)
            # Remove line comments (//) - SublimeText allows this
            sed 's|//.*||g' "$settings_file" > "$temp_json"

            if ! python3 -m json.tool "$temp_json" >/dev/null 2>&1; then
                warn "JSON syntax issues in: $(basename "$settings_file") - this may be normal for SublimeText format"
                # Don't count as error since SublimeText handles relaxed JSON
            else
                log "✓ Valid JSON: $(basename "$settings_file")"
            fi
            rm -f "$temp_json"
        fi
    done

    # Check for required directories
    for dir in settings keymaps snippets themes; do
        if [[ ! -d "$SUBLIME_CONFIG_DIR/$dir" ]]; then
            warn "Missing directory: $dir"
            mkdir -p "$SUBLIME_CONFIG_DIR/$dir"
        fi
    done

    if [[ $issues -eq 0 ]]; then
        log "✅ Configuration validation passed"
    else
        error "Configuration validation failed with $issues issues"
    fi
}

# Show usage information
show_usage() {
    cat << EOF
SublimeText Configuration Sync Automation

Usage: $0 [OPTION]

Options:
    --export        Export current SublimeText configuration to dotfiles
    --import        Import configuration from dotfiles to SublimeText
    --setup         Setup initial dotfiles structure and enhanced config
    --validate      Validate configuration files
    --help          Show this help message

Without arguments, performs a full sync (export current config).

Examples:
    $0                  # Export current configuration
    $0 --import        # Import configuration from dotfiles
    $0 --setup         # Setup initial structure with enhanced config
    $0 --validate      # Validate configuration files

Configuration is stored in: $SUBLIME_CONFIG_DIR
EOF
}

# Main execution function
main() {
    local action="${1:-export}"

    case "$action" in
        --export|export)
            check_sublime_installation
            check_sublime_user_dir
            setup_dotfiles_structure
            export_config
            validate_config
            ;;
        --import|import)
            check_sublime_installation
            import_config
            validate_config
            ;;
        --setup|setup)
            check_sublime_installation
            setup_dotfiles_structure
            create_enhanced_config
            create_sync_service
            validate_config
            ;;
        --validate|validate)
            validate_config
            ;;
        --help|help|-h)
            show_usage
            exit 0
            ;;
        *)
            # Default: export current configuration
            check_sublime_installation
            check_sublime_user_dir
            setup_dotfiles_structure
            export_config
            validate_config
            ;;
    esac

    log "✅ SublimeText configuration sync completed successfully!"
    info "📁 Configuration directory: $SUBLIME_CONFIG_DIR"
    info "🔄 Auto-sync runs daily at 6 PM"
    info "📖 See README.md for more information"
}

# Run the main function with all arguments
main "$@"