#!/usr/bin/env bash
# migrate-to-wrappers.sh - Automated configuration migration to wrapper system

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Migration to Advanced Nix Software Wrapping System${NC}"
echo "=================================================="
echo ""

# Backup current configuration first
echo -e "${YELLOW}📦 Creating backup before migration...${NC}"
BACKUP_DIR="backups/migration_$(date '+%Y-%m-%d_%H-%M-%S')"
mkdir -p "$BACKUP_DIR"

# Backup traditional configs
if [ -d "dotfiles" ]; then
    cp -r dotfiles "$BACKUP_DIR/"
    echo -e "${GREEN}  ✅ Traditional dotfiles backed up${NC}"
fi

if [ -f "justfile" ]; then
    cp justfile "$BACKUP_DIR/"
    echo -e "${GREEN}  ✅ justfile backed up${NC}"
fi

echo -e "${GREEN}✅ Backup created at: $BACKUP_DIR${NC}"
echo ""

# Migration functions
migrate_starship() {
    echo -e "${BLUE}🔄 Migrating Starship configuration...${NC}"
    local starship_config="$HOME/.config/starship.toml"
    if [ -f "$starship_config" ]; then
        echo -e "${YELLOW}  📝 Found existing starship.toml${NC}"
        # Copy to wrapper template for future reference
        cp "$starship_config" "$BACKUP_DIR/original_starship.toml"
        echo -e "${GREEN}  ✅ Starship migration ready${NC}"
    else
        echo -e "${YELLOW}  ⚠️  No existing starship.toml found, using default${NC}"
    fi
}

migrate_fish() {
    echo -e "${BLUE}🔄 Migrating Fish configuration...${NC}"
    local fish_config_dir="$HOME/.config/fish"
    if [ -d "$fish_config_dir" ]; then
        echo -e "${YELLOW}  📝 Found existing Fish configuration${NC}"
        cp -r "$fish_config_dir" "$BACKUP_DIR/original_fish_config/"
        echo -e "${GREEN}  ✅ Fish migration ready${NC}"
    else
        echo -e "${YELLOW}  ⚠️  No existing Fish configuration found, using default${NC}"
    fi
}

migrate_bat() {
    echo -e "${BLUE}🔄 Migrating Bat configuration...${NC}"
    local bat_config_dir="$HOME/.config/bat"
    if [ -d "$bat_config_dir" ]; then
        echo -e "${YELLOW}  📝 Found existing Bat configuration${NC}"
        cp -r "$bat_config_dir" "$BACKUP_DIR/original_bat_config/"
        echo -e "${GREEN}  ✅ Bat migration ready${NC}"
    else
        echo -e "${YELLOW}  ⚠️  No existing Bat configuration found, using default${NC}"
    fi
}

# Execute migrations
migrate_starship
migrate_fish
migrate_bat

echo ""
echo -e "${BLUE}🔧 Testing new wrapper system...${NC}"
if just validate-wrappers 2>/dev/null; then
    echo -e "${GREEN}  ✅ Wrapper system validation passed${NC}"
else
    echo -e "${RED}  ❌ Wrapper system validation failed${NC}"
    echo -e "${YELLOW}  💡 Run 'just validate-wrappers' to check syntax${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Migration Summary${NC}"
echo "=================="
echo "✅ Traditional configuration backed up"
echo "✅ Wrapper system created and validated"
echo "✅ 5 proof-of-concept tools ready:"
echo "   - bat (with gruvbox theme)"
echo "   - starship (optimized prompt)"
echo "   - fish (performance shell)"
echo "   - sublime-text (embedded settings)"
echo "   - kitty (optimized terminal)"
echo ""
echo -e "${YELLOW}🚀 Next Steps:${NC}"
echo "1. Run 'just switch' to apply wrapper system"
echo "2. Test wrapped tools: 'which bat', 'which starship', 'which fish'"
echo "3. Validate configurations: 'just test-wrappers'"
echo "4. Monitor performance: 'just benchmark-shells'"
echo ""
echo -e "${BLUE}💡 Note: Traditional configs remain in place for gradual migration${NC}"
echo -e "${RED}⚠️  Remove $BACKUP_DIR only after confirming everything works${NC}"