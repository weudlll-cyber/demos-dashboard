#!/usr/bin/env bash
# =============================================================================
# update.sh — DEMOS Dashboard: Pull latest changes and redeploy
#
# Usage:
#   bash scripts/update.sh [WEB_ROOT]
#
# Arguments:
#   WEB_ROOT   Directory where built files are served.
#              Default: /var/www/demos-dashboard
#
# What this script does:
#   1. git pull origin main
#   2. npm install (picks up any new/changed dependencies)
#   3. npm run build
#   4. Syncs dist/ to WEB_ROOT
#   5. Reloads nginx
# =============================================================================
set -euo pipefail

# --- Config ------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WEB_ROOT="${1:-/var/www/demos-dashboard}"

# --- Helpers -----------------------------------------------------------------
info()  { echo -e "\033[0;36m[INFO]\033[0m  $*"; }
ok()    { echo -e "\033[0;32m[ OK ]\033[0m  $*"; }
error() { echo -e "\033[0;31m[ERR ]\033[0m  $*" >&2; }

# --- Banner ------------------------------------------------------------------
echo ""
echo "  =============================================="
echo "   DEMOS Node Dashboard — Updater"
echo "  =============================================="
echo "   Project dir : $PROJECT_DIR"
echo "   Web root    : $WEB_ROOT"
echo "  =============================================="
echo ""

# --- Sanity checks -----------------------------------------------------------
if [ ! -d "$PROJECT_DIR/.git" ]; then
  error "Not a git repository: $PROJECT_DIR"
  error "Run install.sh first, or clone the repo."
  exit 1
fi

if [ ! -d "$WEB_ROOT" ]; then
  error "Web root $WEB_ROOT does not exist."
  error "Run install.sh first to set up the environment."
  exit 1
fi

# --- 1. Pull latest changes --------------------------------------------------
info "Pulling latest changes from origin/main..."
cd "$PROJECT_DIR"
git pull origin main
ok "Up to date"

# --- 2. Install / update dependencies ----------------------------------------
echo ""
info "Syncing Node dependencies..."
npm install --production=false
ok "Dependencies up to date"

# --- 3. Build ----------------------------------------------------------------
echo ""
info "Building production bundle..."
npm run build
ok "Build complete — output in dist/"

# --- 4. Deploy ---------------------------------------------------------------
echo ""
info "Deploying files to $WEB_ROOT..."
sudo rsync -a --delete "$PROJECT_DIR/dist/" "$WEB_ROOT/"
ok "Files deployed"

# --- 5. Reload nginx ---------------------------------------------------------
echo ""
info "Reloading nginx..."
sudo systemctl reload nginx
ok "nginx reloaded"

# --- Done --------------------------------------------------------------------
echo ""
echo "  =============================================="
echo "   Update complete! Dashboard is now live."
echo "  =============================================="
echo ""
