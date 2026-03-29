#!/usr/bin/env bash
set -euo pipefail

CONFIG="/var/lib/gitea/custom/conf/app.ini"
GITEA_BIN="/nix/store/8r7dgsz651jlam139g44ik6k44cxvyh3-system-path/bin/gitea"

echo "=== Gitea Users ==="
sudo -u gitea "$GITEA_BIN" admin user list -c "$CONFIG"

echo ""
echo "Resetting password for lars..."
sudo -u gitea "$GITEA_BIN" admin user change-password -c "$CONFIG" --username lars --password changeme123

echo ""
echo "Done. Login at http://localhost:3000 with user 'lars' and password 'changeme123'"
