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
#   1. Asks a few questions (domain, HTTPS email) — then handles everything
#   2. Installs Node.js 20 LTS if not present
#   3. Installs nginx if not present
#   4. Runs npm install && npm run build
#   5. Deploys dist/ to WEB_ROOT with hardened file permissions
#   6. Installs the nginx config, sets your domain, enables the site
#   7. Optionally: runs certbot, obtains a free HTTPS certificate,
#      appends the hardened HTTPS server block, and enables the redirect
# =============================================================================
set -euo pipefail

# --- Config ------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WEB_ROOT="${1:-/var/www/demos-dashboard}"
NGINX_AVAILABLE="/etc/nginx/sites-available/demos-dashboard"
NGINX_ENABLED="/etc/nginx/sites-enabled/demos-dashboard"

# Runtime state — filled in by interactive prompts below
DOMAIN=""
CERTBOT_EMAIL=""
SETUP_HTTPS="n"
HTTPS_ACTIVE="n"

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

# --- Interactive setup -------------------------------------------------------
# Ask a few questions up front so the rest of the install runs unattended.
echo "  ── Setup questions ──────────────────────────"
echo ""
echo "  This installer will handle Node.js, nginx, building the dashboard,"
echo "  deploying it, and optionally HTTPS — all automatically."
echo "  Press ENTER to skip any optional step."
echo ""

read -rp "  Domain name (e.g. demo.example.com) [skip — use IP]: " DOMAIN
DOMAIN="${DOMAIN:-}"

if [ -n "$DOMAIN" ]; then
  info "Domain: $DOMAIN"
  echo ""
  read -rp "  Email for Let's Encrypt HTTPS certificate [skip HTTPS]: " CERTBOT_EMAIL
  CERTBOT_EMAIL="${CERTBOT_EMAIL:-}"
  if [ -n "$CERTBOT_EMAIL" ]; then
    SETUP_HTTPS="y"
    info "HTTPS will be set up automatically for $DOMAIN"
    echo ""
    echo "  IMPORTANT: Before continuing, make sure:"
    echo "    1.  $DOMAIN points to this server's IP in your DNS."
    echo "    2.  Port 80 is open in your firewall (needed for certificate verification)."
    echo "    3.  You can check DNS with:  dig +short $DOMAIN"
    echo ""
    read -rp "  DNS is pointing to this server. Continue? [Y/n] " dns_ok
    [[ "${dns_ok:-Y}" =~ ^[Nn] ]] && { warn "Aborting. Fix DNS and re-run the installer."; exit 0; }
  else
    warn "No email provided — skipping automatic HTTPS."
    warn "You can set up HTTPS later: sudo certbot --nginx -d $DOMAIN"
  fi
else
  warn "No domain — dashboard will be accessible by IP address."
  warn "You can add a domain later by editing: $NGINX_AVAILABLE"
fi

echo ""
echo "  ── Starting installation ─────────────────────"
echo ""

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

# rsync: copy everything from dist/ into WEB_ROOT and remove stale files.
sudo rsync -a --delete "$PROJECT_DIR/dist/" "$WEB_ROOT/"

# Harden web root permissions:
#   - Owned by www-data (the nginx worker user) so nginx can read the files.
#   - Directories: 755 (owner rwx, group+others r-x) — nginx can traverse them.
#   - Files:       644 (owner rw, group+others r) — readable, not executable.
#   - No world-writable files. If a file were world-writable an attacker who
#     can write to the filesystem could replace served JS/CSS with malware.
sudo chown -R www-data:www-data "$WEB_ROOT"
sudo find "$WEB_ROOT" -type d -exec chmod 755 {} \;
sudo find "$WEB_ROOT" -type f -exec chmod 644 {} \;
ok "Files deployed with hardened permissions (www-data:www-data, 644/755)"

# --- 5. Nginx config ---------------------------------------------------------
echo ""
info "Installing nginx configuration..."
sudo cp "$SCRIPT_DIR/nginx.conf" "$NGINX_AVAILABLE"
sudo sed -i "s|__WEB_ROOT__|$WEB_ROOT|g" "$NGINX_AVAILABLE"

# Substitute domain placeholder.
# If no domain was given, use _ (nginx catch-all — serves requests by IP).
if [ -n "$DOMAIN" ]; then
  sudo sed -i "s|__DOMAIN__|$DOMAIN|g" "$NGINX_AVAILABLE"
  info "Domain set to: $DOMAIN"
else
  sudo sed -i "s|server_name __DOMAIN__;|server_name _;|" "$NGINX_AVAILABLE"
  info "server_name set to _ (IP access — add a domain later if needed)"
fi

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
ok "nginx configured and running"

# --- 6. HTTPS with Let's Encrypt (optional) ----------------------------------
if [ "$SETUP_HTTPS" = "y" ]; then
  echo ""
  echo "  ── Step 6: HTTPS ────────────────────────────"
  echo ""

  # Install certbot if not already present
  if ! command -v certbot &>/dev/null; then
    info "Installing certbot..."
    sudo apt-get install -y --quiet certbot
    ok "certbot installed"
  else
    ok "certbot already installed"
  fi

  # The ACME webroot challenge uses /var/www/html — nginx serves
  # /.well-known/acme-challenge/ from there (see nginx.conf).
  sudo mkdir -p /var/www/html

  info "Requesting Let's Encrypt certificate for: $DOMAIN"
  info "(Let's Encrypt will verify you own $DOMAIN by fetching a token from port 80)"
  echo ""

  if sudo certbot certonly \
       --webroot \
       -w /var/www/html \
       -d "$DOMAIN" \
       --email "$CERTBOT_EMAIL" \
       --agree-tos \
       --non-interactive; then

    ok "Certificate obtained: /etc/letsencrypt/live/$DOMAIN/"

    # Append the hardened HTTPS server block (nginx-https.conf) to the
    # installed nginx config. This block includes our full CSP, HSTS,
    # Permissions-Policy, gzip, /api proxy — everything already configured.
    info "Appending hardened HTTPS server block..."
    HTTPS_TMP=$(mktemp)
    sed "s|__DOMAIN__|$DOMAIN|g; s|__WEB_ROOT__|$WEB_ROOT|g" \
      "$SCRIPT_DIR/nginx-https.conf" > "$HTTPS_TMP"
    sudo tee -a "$NGINX_AVAILABLE" < "$HTTPS_TMP" > /dev/null
    rm -f "$HTTPS_TMP"
    ok "HTTPS server block added"

    # Enable the HTTP → HTTPS redirect in the HTTP server block.
    # The redirect line exists in nginx.conf but is commented out.
    sudo sed -i 's|^    # return 301 https://|    return 301 https://|' "$NGINX_AVAILABLE"
    ok "HTTP → HTTPS redirect enabled"

    sudo nginx -t
    sudo systemctl reload nginx
    HTTPS_ACTIVE="y"
    ok "HTTPS is live at https://$DOMAIN"
    echo ""
    echo "  Certificates auto-renew every ~60 days via a systemd timer."
    echo "  Test the renewal process at any time with:"
    echo "    sudo certbot renew --dry-run"

  else
    warn "certbot failed to obtain a certificate."
    warn ""
    warn "  Common causes:"
    warn "  1. DNS not pointing here yet — check: dig +short $DOMAIN"
    warn "     It must return this server's IP: $(hostname -I | awk '{print $1}')"
    warn "  2. Port 80 blocked — check: sudo ufw status"
    warn "  3. nginx not serving on port 80 — check: curl -I http://$DOMAIN/"
    warn ""
    warn "  Retry HTTPS later with:"
    warn "    sudo certbot certonly --webroot -w /var/www/html -d $DOMAIN --email $CERTBOT_EMAIL --agree-tos"
    warn "    Then run: bash scripts/https-activate.sh"
  fi
fi

# --- Done --------------------------------------------------------------------
SERVER_IP=$(hostname -I | awk '{print $1}')
echo ""
echo "  =============================================="
echo "   Installation complete!"
echo ""
if [ "$HTTPS_ACTIVE" = "y" ]; then
  echo "   Dashboard is live at:"
  echo "   https://$DOMAIN"
  echo ""
  echo "   http:// requests redirect to https:// automatically."
elif [ -n "$DOMAIN" ]; then
  echo "   Dashboard is live at:"
  echo "   http://$DOMAIN    (if DNS is already pointing here)"
  echo "   http://$SERVER_IP  (always works by IP)"
  echo ""
  echo "   To enable HTTPS later:"
  echo "   sudo certbot certonly --webroot -w /var/www/html \\"
  echo "        -d $DOMAIN --email YOUR_EMAIL --agree-tos"
  echo "   Then: bash scripts/https-activate.sh"
else
  echo "   Dashboard is live at:"
  echo "   http://$SERVER_IP"
  echo ""
  echo "   To add a domain and HTTPS later, see: docs/VPS_SETUP.md"
fi
echo ""
echo "   To update the dashboard after code changes:"
echo "   cd $PROJECT_DIR && bash scripts/update.sh"
echo ""
echo "   Full guide: docs/VPS_SETUP.md"
echo "   Troubleshooting help: docs/VPS_SETUP.md#troubleshooting"
echo "  =============================================="
echo ""
