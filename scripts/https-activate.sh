#!/usr/bin/env bash
# =============================================================================
# https-activate.sh — DEMOS Dashboard: Activate HTTPS after manual certbot run
#
# Run this script AFTER you have obtained a Let's Encrypt certificate manually:
#   sudo certbot certonly --webroot -w /var/www/html \
#        -d YOUR_DOMAIN --email YOUR_EMAIL --agree-tos
#
# Usage:
#   bash scripts/https-activate.sh DOMAIN [WEB_ROOT]
#
# Arguments:
#   DOMAIN     Your domain name (e.g. demo.example.com)   ← REQUIRED
#   WEB_ROOT   Web root path. Default: /var/www/demos-dashboard
#
# What this script does:
#   1. Verifies the certificate exists at /etc/letsencrypt/live/DOMAIN/
#   2. Appends the hardened HTTPS server block (scripts/nginx-https.conf)
#      to the nginx config
#   3. Enables the HTTP → HTTPS redirect in the HTTP server block
#   4. Runs nginx -t and reloads nginx
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NGINX_AVAILABLE="/etc/nginx/sites-available/demos-dashboard"

# --- Helpers -----------------------------------------------------------------
info()  { echo -e "\033[0;36m[INFO]\033[0m  $*"; }
ok()    { echo -e "\033[0;32m[ OK ]\033[0m  $*"; }
warn()  { echo -e "\033[0;33m[WARN]\033[0m  $*"; }
error() { echo -e "\033[0;31m[ERR ]\033[0m  $*" >&2; }

# --- Args --------------------------------------------------------------------
if [ -z "${1:-}" ]; then
  error "Usage: bash scripts/https-activate.sh YOUR_DOMAIN [WEB_ROOT]"
  error "Example: bash scripts/https-activate.sh demo.example.com"
  exit 1
fi

DOMAIN="$1"
WEB_ROOT="${2:-/var/www/demos-dashboard}"

echo ""
echo "  ================================================"
echo "   DEMOS Dashboard — HTTPS Activation"
echo "   Domain   : $DOMAIN"
echo "   Web root : $WEB_ROOT"
echo "  ================================================"
echo ""

# --- 1. Verify certificate ---------------------------------------------------
CERT_DIR="/etc/letsencrypt/live/$DOMAIN"
if [ ! -f "$CERT_DIR/fullchain.pem" ]; then
  error "Certificate not found at $CERT_DIR/fullchain.pem"
  error ""
  error "Obtain a certificate first:"
  error "  sudo certbot certonly --webroot -w /var/www/html \\"
  error "       -d $DOMAIN --email YOUR_EMAIL --agree-tos"
  exit 1
fi
ok "Certificate found: $CERT_DIR/fullchain.pem"

# --- 2. Check nginx config exists --------------------------------------------
if [ ! -f "$NGINX_AVAILABLE" ]; then
  error "nginx config not found: $NGINX_AVAILABLE"
  error "Run scripts/install.sh first."
  exit 1
fi

# --- 3. Check HTTPS block not already added ----------------------------------
if grep -q "listen 443" "$NGINX_AVAILABLE" 2>/dev/null; then
  warn "The nginx config already has a 'listen 443' block."
  warn "HTTPS may already be active. Aborting to avoid duplicates."
  warn ""
  warn "Check your current config: sudo cat $NGINX_AVAILABLE"
  exit 0
fi

# --- 4. Append hardened HTTPS server block -----------------------------------
info "Appending hardened HTTPS server block..."
HTTPS_TMP=$(mktemp)
sed "s|__DOMAIN__|$DOMAIN|g; s|__WEB_ROOT__|$WEB_ROOT|g" \
  "$SCRIPT_DIR/nginx-https.conf" > "$HTTPS_TMP"
sudo tee -a "$NGINX_AVAILABLE" < "$HTTPS_TMP" > /dev/null
rm -f "$HTTPS_TMP"
ok "HTTPS server block added"

# --- 5. Enable HTTP → HTTPS redirect -----------------------------------------
info "Enabling HTTP → HTTPS redirect..."
sudo sed -i 's|^    # return 301 https://|    return 301 https://|' "$NGINX_AVAILABLE"
ok "Redirect enabled"

# --- 6. Test and reload nginx ------------------------------------------------
info "Testing nginx configuration..."
sudo nginx -t

info "Reloading nginx..."
sudo systemctl reload nginx

# --- Done --------------------------------------------------------------------
echo ""
echo "  ================================================"
echo "   HTTPS activation complete!"
echo ""
echo "   Dashboard is live at: https://$DOMAIN"
echo ""
echo "   HTTP requests now redirect to HTTPS automatically."
echo ""
echo "   Certificate auto-renewal is managed by certbot."
echo "   Test renewal at any time: sudo certbot renew --dry-run"
echo ""
echo "   When you are happy everything is working, increase HSTS:"
echo "   sudo sed -i 's/max-age=300/max-age=31536000/' $NGINX_AVAILABLE"
echo "   sudo nginx -t && sudo systemctl reload nginx"
echo "  ================================================"
echo ""
