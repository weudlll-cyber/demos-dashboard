#!/usr/bin/env bash
# =============================================================================
# install.sh — DEMOS Dashboard: First-time VPS installer
#
# Usage:
#   bash scripts/install.sh [WEB_ROOT]
#
# Arguments:
#   WEB_ROOT   Directory where built files are served from.
#              Default: /var/www/demos-dashboard
#
# Requirements:
#   - Ubuntu 22.04 or 24.04 (Debian-based distros)
#   - sudo access
#   - The repo must already be cloned on the VPS
#
# What this script does:
#   1. Installs Node.js 20 LTS if not present
#   2. Installs nginx if not present
#   3. Runs npm install && npm run build
#   4. Deploys dist/ to WEB_ROOT
#   5. Installs the nginx config and enables the site
#   6. Reloads nginx
# =============================================================================
set -euo pipefail

# --- Config ------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WEB_ROOT="${1:-/var/www/demos-dashboard}"
NGINX_AVAILABLE="/etc/nginx/sites-available/demos-dashboard"
NGINX_ENABLED="/etc/nginx/sites-enabled/demos-dashboard"

# --- Helpers -----------------------------------------------------------------
info()  { echo -e "\033[0;36m[INFO]\033[0m  $*"; }
ok()    { echo -e "\033[0;32m[ OK ]\033[0m  $*"; }
warn()  { echo -e "\033[0;33m[WARN]\033[0m  $*"; }
error() { echo -e "\033[0;31m[ERR ]\033[0m  $*" >&2; }

# --- Banner ------------------------------------------------------------------
echo ""
echo "  =============================================="
echo "   DEMOS Node Dashboard — VPS Installer"
echo "  =============================================="
echo "   Project dir : $PROJECT_DIR"
echo "   Web root    : $WEB_ROOT"
echo "  =============================================="
echo ""

# --- 1. Node.js --------------------------------------------------------------
if command -v node &>/dev/null; then
  ok "Node.js $(node -v) already installed"
else
  info "Node.js not found — installing Node.js 20 LTS via NodeSource..."
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt-get install -y nodejs
  ok "Node.js $(node -v) installed"
fi

# --- 2. nginx ----------------------------------------------------------------
if command -v nginx &>/dev/null; then
  ok "nginx already installed"
else
  info "nginx not found — installing..."
  sudo apt-get update
  sudo apt-get install -y nginx
  ok "nginx installed"
fi

# --- 3. Build ----------------------------------------------------------------
echo ""
info "Installing Node dependencies..."
cd "$PROJECT_DIR"
npm install --production=false

info "Building production bundle..."
npm run build
ok "Build complete — output in dist/"

# --- 4. Deploy static files --------------------------------------------------
echo ""
info "Deploying files to $WEB_ROOT..."
sudo mkdir -p "$WEB_ROOT"

# rsync: copy everything from dist/ into WEB_ROOT and remove files no longer in dist/
sudo rsync -a --delete "$PROJECT_DIR/dist/" "$WEB_ROOT/"
ok "Files deployed"

# --- 5. Nginx config ---------------------------------------------------------
echo ""
info "Installing nginx configuration..."
sudo cp "$SCRIPT_DIR/nginx.conf" "$NGINX_AVAILABLE"
sudo sed -i "s|__WEB_ROOT__|$WEB_ROOT|g" "$NGINX_AVAILABLE"

# Enable site (create symlink if not already there)
if [ ! -L "$NGINX_ENABLED" ]; then
  sudo ln -s "$NGINX_AVAILABLE" "$NGINX_ENABLED"
  info "Site enabled"
else
  warn "Symlink already exists — skipping"
fi

# Remove default site if it would conflict on port 80
if [ -L "/etc/nginx/sites-enabled/default" ]; then
  warn "Removing default nginx site to avoid port 80 conflict"
  sudo rm /etc/nginx/sites-enabled/default
fi

# Test and reload
sudo nginx -t
sudo systemctl enable nginx
sudo systemctl reload nginx
ok "nginx configured and reloaded"

# --- Done --------------------------------------------------------------------
echo ""
echo "  =============================================="
echo "   Installation complete!"
echo ""
echo "   The dashboard is now live at:"
echo "   http://$(hostname -I | awk '{print $1}')"
echo ""
echo "   Next steps:"
echo "   - Point your domain to this server's IP"
echo "   - Enable HTTPS:  sudo certbot --nginx -d your-domain.com"
echo "   - See docs/VPS_SETUP.md for the full guide"
echo "  =============================================="
echo ""
