#!/usr/bin/env bash
# =============================================================================
# install.sh — DEMOS Dashboard: Guided first-time installer
#
# Just run:  bash scripts/install.sh
# The script will walk you through every step with clear instructions.
# No other documentation is needed for a standard installation.
#
# Requirements:
#   - Ubuntu 22.04 or 24.04 LTS
#   - sudo access (you will be asked for your password once)
#   - The repo already cloned on the VPS (you are running this from inside it)
# =============================================================================
set -euo pipefail

# --- Config ------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WEB_ROOT="${1:-/var/www/demos-dashboard}"
NGINX_AVAILABLE="/etc/nginx/sites-available/demos-dashboard"
NGINX_ENABLED="/etc/nginx/sites-enabled/demos-dashboard"

# Runtime state — filled in during the wizard below
DOMAIN=""
CERTBOT_EMAIL=""
SETUP_HTTPS="n"
HTTPS_ACTIVE="n"
SERVER_IP=""

# --- Helpers -----------------------------------------------------------------
info()    { echo -e "\033[0;36m[INFO]\033[0m  $*"; }
ok()      { echo -e "\033[0;32m[ OK ]\033[0m  $*"; }
warn()    { echo -e "\033[0;33m[WARN]\033[0m  $*"; }
error()   { echo -e "\033[0;31m[ERR ]\033[0m  $*" >&2; }
step()    { echo ""; echo -e "\033[1;37m  ── $* \033[0m"; echo ""; }
tip()     { echo -e "\033[0;35m  [TIP]\033[0m  $*"; }
divider() { echo "  ──────────────────────────────────────────────"; }

# --- Detect server IP --------------------------------------------------------
# Used throughout the wizard so the user knows what to enter in their DNS.
SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
if [ -z "$SERVER_IP" ]; then
  SERVER_IP="(could not detect — check your VPS control panel)"
fi

# =============================================================================
# BANNER
# =============================================================================
clear
echo ""
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║   DEMOS Node Dashboard — Installer Wizard   ║"
echo "  ╚══════════════════════════════════════════════╝"
echo ""
echo "  This wizard installs and fully configures the dashboard."
echo "  Just answer the questions — the rest is automatic."
echo ""
echo "  Your server's IP address:  $SERVER_IP"
echo "  (You will need this when setting up a domain)"
echo ""
divider
echo ""
echo "  What this installer does:"
echo "   1.  Installs all required software (Node.js, nginx)"
echo "   2.  Builds the dashboard"
echo "   3.  Deploys it to the web server"
echo "   4.  Configures the firewall (opens ports 80 and 443)"
echo "   5.  Optionally: sets up a free HTTPS certificate (Let's Encrypt)"
echo ""
echo "  Total time: about 3–5 minutes."
echo ""
read -rp "  Press ENTER to start..." _unused

# =============================================================================
# WIZARD — QUESTION 1: Domain
# =============================================================================
step "Question 1 of 2 — Domain name"

echo "  A domain name lets people reach your dashboard via a memorable"
echo "  address like  demo.example.com  instead of a raw IP address."
echo ""
echo "  ┌─ Do you have a domain name you want to use? ──────────────────┐"
echo "  │                                                                │"
echo "  │  YES → Enter your domain name below.                          │"
echo "  │  NO  → Press ENTER to skip. The dashboard will be reachable   │"
echo "  │         by IP address:  http://$SERVER_IP                     │"
echo "  │         You can always add a domain later.                    │"
echo "  └────────────────────────────────────────────────────────────────┘"
echo ""
tip "Don't have a domain yet? You can get one cheaply at:"
tip "  Namecheap (namecheap.com) — from ~\$10/year"
tip "  Cloudflare (cloudflare.com) — from ~\$10/year, also free DNS"
tip "  Porkbun (porkbun.com)     — often the cheapest option"
echo ""
read -rp "  Domain name (e.g. demo.example.com) or ENTER to skip: " DOMAIN
DOMAIN="${DOMAIN:-}"

if [ -n "$DOMAIN" ]; then
  echo ""
  ok "Domain recorded: $DOMAIN"
  echo ""

  # ── DNS setup instructions ────────────────────────────────────────────────
  echo "  ┌─ ACTION REQUIRED before HTTPS can work ───────────────────────┐"
  echo "  │                                                                │"
  echo "  │  You need to add a DNS record at your domain registrar        │"
  echo "  │  pointing  $DOMAIN  to this server.          │"
  echo "  │                                                                │"
  echo "  │  Log in to your domain registrar (Namecheap, Cloudflare,      │"
  echo "  │  etc.) and go to the DNS settings for your domain.            │"
  echo "  │                                                                │"
  echo "  │  Add this DNS record:                                         │"
  echo "  │                                                                │"
  echo "  │    Type:    A                                                  │"
  echo "  │    Name:    $(echo "$DOMAIN" | cut -d. -f1)  (or @ if using root domain)               │"
  echo "  │    Value:   $SERVER_IP                              │"
  echo "  │    TTL:     Auto  (or 300 seconds)                            │"
  echo "  │                                                                │"
  echo "  │  EXAMPLE (Cloudflare):                                        │"
  echo "  │    DNS → Add record → Type: A → Name: demo → IPv4: $SERVER_IP │"
  echo "  │                                                                │"
  echo "  │  EXAMPLE (Namecheap):                                         │"
  echo "  │    Domain List → Manage → Advanced DNS → Add New Record       │"
  echo "  │    → A Record, Host: demo, Value: $SERVER_IP, TTL: Auto       │"
  echo "  │                                                                │"
  echo "  │  DNS changes can take 1–30 minutes to take effect.            │"
  echo "  │  The installer will check automatically before requesting     │"
  echo "  │  the HTTPS certificate.                                       │"
  echo "  └────────────────────────────────────────────────────────────────┘"
  echo ""
  read -rp "  Press ENTER once you have added the DNS record (or if you did it earlier)..." _unused
else
  echo ""
  warn "No domain — the dashboard will be reachable at:  http://$SERVER_IP"
  warn "You can add a domain and HTTPS later by re-running this installer."
fi

# =============================================================================
# WIZARD — QUESTION 2: HTTPS email (only if domain was given)
# =============================================================================
if [ -n "$DOMAIN" ]; then
  step "Question 2 of 2 — HTTPS certificate"

  echo "  HTTPS encrypts the connection between the browser and the server."
  echo "  Without it, anyone between the visitor and the server can see"
  echo "  the dashboard traffic as plain text."
  echo ""
  echo "  Let's Encrypt provides FREE certificates automatically."
  echo "  All it needs is an email address — this is only used to send you"
  echo "  a warning if your certificate is about to expire (very rare, as"
  echo "  renewal happens automatically)."
  echo ""
  echo "  ┌─ Do you want a free HTTPS certificate? ───────────────────────┐"
  echo "  │                                                                │"
  echo "  │  YES → Enter your email address below.                        │"
  echo "  │  NO  → Press ENTER to skip. Dashboard will run on HTTP only.  │"
  echo "  │         You can enable HTTPS later at any time.               │"
  echo "  └────────────────────────────────────────────────────────────────┘"
  echo ""
  read -rp "  Your email address or ENTER to skip HTTPS: " CERTBOT_EMAIL
  CERTBOT_EMAIL="${CERTBOT_EMAIL:-}"

  if [ -n "$CERTBOT_EMAIL" ]; then
    SETUP_HTTPS="y"
    echo ""
    ok "HTTPS will be configured automatically for $DOMAIN"
  else
    echo ""
    warn "Skipping HTTPS — dashboard will run on HTTP only."
    warn "To add HTTPS later:"
    warn "  sudo certbot certonly --webroot -w /var/www/html -d $DOMAIN --email YOUR@EMAIL.COM --agree-tos"
    warn "  bash scripts/https-activate.sh $DOMAIN"
  fi
fi

# =============================================================================
# SUMMARY — show what will happen, then confirm
# =============================================================================
step "Summary — review before installation starts"

echo "  The following will be installed and configured automatically:"
echo ""
echo "   Software:    Node.js 20 LTS, nginx, certbot (if HTTPS chosen)"
echo "   Build:       npm install + npm run build"
echo "   Web root:    $WEB_ROOT"
echo "   Firewall:    UFW — ports 22/SSH, 80/HTTP, 443/HTTPS opened"
if [ -n "$DOMAIN" ]; then
  echo "   Domain:      $DOMAIN"
else
  echo "   Domain:      none (IP access only: http://$SERVER_IP)"
fi
if [ "$SETUP_HTTPS" = "y" ]; then
  echo "   HTTPS:       YES — free certificate from Let's Encrypt"
  echo "                     auto-renews every 60 days"
else
  echo "   HTTPS:       no (can be added later)"
fi
echo ""
read -rp "  Everything looks correct? Press ENTER to start installation, or Ctrl+C to cancel." _unused

# =============================================================================
# INSTALLATION
# =============================================================================

step "Step 1 of 6 — Installing required software"

# Ensure apt is up to date before installing anything
sudo apt-get update -qq

# Node.js
if command -v node &>/dev/null; then
  ok "Node.js $(node -v) already installed"
else
  info "Installing Node.js 20 LTS..."
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - -qq
  sudo apt-get install -y -qq nodejs
  ok "Node.js $(node -v) installed"
fi

# nginx
if command -v nginx &>/dev/null; then
  ok "nginx already installed"
else
  info "Installing nginx..."
  sudo apt-get install -y -qq nginx
  ok "nginx installed"
fi

# rsync (used to deploy files)
if ! command -v rsync &>/dev/null; then
  sudo apt-get install -y -qq rsync
fi

# unattended-upgrades: keeps the OS security patches applied automatically.
# This is a best-practice for any internet-facing server.
if ! dpkg -l unattended-upgrades &>/dev/null; then
  info "Installing unattended-upgrades (automatic OS security patches)..."
  sudo apt-get install -y -qq unattended-upgrades
  echo 'Unattended-Upgrade::Automatic-Reboot "false";' \
    | sudo tee /etc/apt/apt.conf.d/52-no-reboot > /dev/null
  ok "unattended-upgrades installed (security patches applied automatically)"
fi

step "Step 2 of 6 — Building the dashboard"

cd "$PROJECT_DIR"
info "Installing Node dependencies..."
npm install --production=false --silent

info "Building production bundle..."
npm run build
ok "Build complete"

step "Step 3 of 6 — Deploying files"

info "Copying built files to $WEB_ROOT..."
sudo mkdir -p "$WEB_ROOT"
sudo rsync -a --delete "$PROJECT_DIR/dist/" "$WEB_ROOT/"

# Set secure file permissions:
#   www-data = the user nginx runs as; it needs to read these files.
#   644 on files and 755 on directories = readable by nginx, not world-writable.
sudo chown -R www-data:www-data "$WEB_ROOT"
sudo find "$WEB_ROOT" -type d -exec chmod 755 {} \;
sudo find "$WEB_ROOT" -type f -exec chmod 644 {} \;
ok "Files deployed to $WEB_ROOT"

step "Step 4 of 6 — Configuring nginx web server"

sudo mkdir -p /var/www/html   # ACME challenge dir used by certbot renewal
sudo cp "$SCRIPT_DIR/nginx.conf" "$NGINX_AVAILABLE"
sudo sed -i "s|__WEB_ROOT__|$WEB_ROOT|g" "$NGINX_AVAILABLE"

if [ -n "$DOMAIN" ]; then
  sudo sed -i "s|__DOMAIN__|$DOMAIN|g" "$NGINX_AVAILABLE"
  info "nginx: domain set to $DOMAIN"
else
  sudo sed -i "s|server_name __DOMAIN__;|server_name _;|" "$NGINX_AVAILABLE"
  info "nginx: configured for IP access"
fi

# Enable the site (remove any conflicting default)
[ ! -L "$NGINX_ENABLED" ] && sudo ln -s "$NGINX_AVAILABLE" "$NGINX_ENABLED"
[ -L "/etc/nginx/sites-enabled/default" ] && sudo rm /etc/nginx/sites-enabled/default

sudo nginx -t
sudo systemctl enable --now nginx
sudo systemctl reload nginx
ok "nginx configured and running"

step "Step 5 of 6 — Configuring firewall (UFW)"

# Install UFW if not present (it is included in Ubuntu by default)
if ! command -v ufw &>/dev/null; then
  sudo apt-get install -y -qq ufw
fi

sudo ufw allow OpenSSH   --quiet   # SSH  — keep access to your server
sudo ufw allow 80/tcp    --quiet   # HTTP
sudo ufw allow 443/tcp   --quiet   # HTTPS
# Enable UFW non-interactively (--force skips "may disrupt existing ssh" prompt)
sudo ufw --force enable > /dev/null
ok "Firewall active — SSH (22), HTTP (80), HTTPS (443) open"

# =============================================================================
# HTTPS SETUP
# =============================================================================
if [ "$SETUP_HTTPS" = "y" ]; then
  step "Step 6 of 6 — HTTPS certificate (Let's Encrypt)"

  # Install certbot
  if ! command -v certbot &>/dev/null; then
    info "Installing certbot..."
    sudo apt-get install -y -qq certbot
    ok "certbot installed"
  fi

  # --- DNS check: verify $DOMAIN resolves to this server before trying certbot.
  # Let's Encrypt will fail if DNS is not pointing here yet, and it rate-limits
  # failed attempts (5 failures per domain per hour). We check first.
  info "Checking DNS for $DOMAIN..."
  RESOLVED_IP=""
  if command -v dig &>/dev/null; then
    RESOLVED_IP=$(dig +short "$DOMAIN" A 2>/dev/null | tail -1)
  elif command -v host &>/dev/null; then
    RESOLVED_IP=$(host "$DOMAIN" 2>/dev/null | awk '/has address/{print $NF}' | head -1)
  fi

  DNS_OK="n"
  if [ "$RESOLVED_IP" = "$SERVER_IP" ]; then
    ok "DNS check passed: $DOMAIN → $RESOLVED_IP"
    DNS_OK="y"
  else
    echo ""
    warn "DNS check: $DOMAIN resolves to '${RESOLVED_IP:-nothing}'"
    warn "           but this server's IP is $SERVER_IP"
    warn ""
    warn "  DNS is not pointing here yet (or the change has not propagated)."
    warn ""
    warn "  What to do:"
    warn "    1. Log in to your domain registrar (e.g. Namecheap, Cloudflare)"
    warn "    2. Go to DNS settings for $DOMAIN"
    warn "    3. Add or update this record:"
    warn "         Type: A   |   Name: $(echo "$DOMAIN" | cut -d. -f1)   |   Value: $SERVER_IP"
    warn "    4. Wait 5–30 minutes, then run this installer again."
    warn ""
    warn "  You can check if DNS has propagated with:"
    warn "    dig +short $DOMAIN"
    warn "  It should return:  $SERVER_IP"
    echo ""
    read -rp "  Try to get the certificate anyway? (only if you are sure DNS is correct) [y/N] " force_https
    [[ "${force_https:-N}" =~ ^[Yy] ]] && DNS_OK="y"
  fi

  if [ "$DNS_OK" = "y" ]; then
    info "Requesting certificate from Let's Encrypt for: $DOMAIN"
    info "(Let's Encrypt connects to port 80 on $DOMAIN to verify you own it)"
    echo ""

    if sudo certbot certonly \
         --webroot \
         -w /var/www/html \
         -d "$DOMAIN" \
         --email "$CERTBOT_EMAIL" \
         --agree-tos \
         --non-interactive; then

      ok "Certificate obtained!"
      info "Certificate files:"
      info "  /etc/letsencrypt/live/$DOMAIN/fullchain.pem"
      info "  /etc/letsencrypt/live/$DOMAIN/privkey.pem"

      # Append the hardened HTTPS server block from nginx-https.conf
      info "Adding HTTPS server block to nginx config..."
      HTTPS_TMP=$(mktemp)
      sed "s|__DOMAIN__|$DOMAIN|g; s|__WEB_ROOT__|$WEB_ROOT|g" \
        "$SCRIPT_DIR/nginx-https.conf" > "$HTTPS_TMP"
      sudo tee -a "$NGINX_AVAILABLE" < "$HTTPS_TMP" > /dev/null
      rm -f "$HTTPS_TMP"

      # Uncomment the HTTP → HTTPS redirect line in the HTTP server block
      sudo sed -i 's|^    # return 301 https://|    return 301 https://|' "$NGINX_AVAILABLE"

      sudo nginx -t
      sudo systemctl reload nginx
      HTTPS_ACTIVE="y"
      ok "HTTPS is live at https://$DOMAIN"

    else
      warn "certbot failed to obtain a certificate."
      warn ""
      warn "  Most common cause: DNS not pointing to this server yet."
      warn "  Check: dig +short $DOMAIN  → should return $SERVER_IP"
      warn ""
      warn "  Let's Encrypt rate-limits failed attempts."
      warn "  Wait until DNS is correct, then retry:"
      warn ""
      warn "    sudo certbot certonly --webroot -w /var/www/html \\"
      warn "         -d $DOMAIN --email $CERTBOT_EMAIL --agree-tos"
      warn "    bash scripts/https-activate.sh $DOMAIN"
      warn ""
      warn "  The dashboard is still running on HTTP in the meantime."
    fi
  else
    warn "Skipping HTTPS — DNS is not ready yet."
    warn "Run  bash scripts/https-activate.sh $DOMAIN  after DNS propagates."
  fi
else
  step "Step 6 of 6 — HTTPS"
  info "Skipped (no email provided)."
  if [ -n "$DOMAIN" ]; then
    tip "To enable HTTPS later:"
    tip "  sudo certbot certonly --webroot -w /var/www/html -d $DOMAIN --email YOU@EXAMPLE.COM --agree-tos"
    tip "  bash scripts/https-activate.sh $DOMAIN"
  fi
fi

# =============================================================================
# FINAL SUMMARY
# =============================================================================
echo ""
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║        Installation complete!               ║"
echo "  ╚══════════════════════════════════════════════╝"
echo ""

if [ "$HTTPS_ACTIVE" = "y" ]; then
  echo "  Your dashboard is live at:"
  echo ""
  echo "    https://$DOMAIN    ← use this"
  echo "    http://$SERVER_IP  ← also works (redirects to HTTPS)"
  echo ""
  echo "  HTTPS certificate:"
  echo "    Auto-renews every ~60 days. No action needed."
  echo "    Test the renewal process: sudo certbot renew --dry-run"
  echo ""
  echo "  Optional: Once you are happy everything is stable, increase the"
  echo "  HTTPS security timeout from 5 minutes to 1 year:"
  echo "    sudo sed -i 's/max-age=300/max-age=31536000/' $NGINX_AVAILABLE"
  echo "    sudo nginx -t && sudo systemctl reload nginx"
elif [ -n "$DOMAIN" ]; then
  echo "  Your dashboard is live at:"
  echo ""
  echo "    http://$DOMAIN    (if DNS is already pointing here)"
  echo "    http://$SERVER_IP  (works immediately by IP)"
  echo ""
  echo "  When you are ready to add HTTPS (recommended!):"
  echo "    1. Make sure DNS is pointing here: dig +short $DOMAIN"
  echo "       Should return: $SERVER_IP"
  echo "    2. Run:"
  echo "       sudo certbot certonly --webroot -w /var/www/html \\"
  echo "            -d $DOMAIN --email YOUR@EMAIL.COM --agree-tos"
  echo "       bash scripts/https-activate.sh $DOMAIN"
else
  echo "  Your dashboard is live at:"
  echo ""
  echo "    http://$SERVER_IP"
  echo ""
  echo "  To add a domain + HTTPS later:"
  echo "    1. Buy a domain (namecheap.com, porkbun.com, cloudflare.com)"
  echo "    2. Add an A record pointing to:  $SERVER_IP"
  echo "    3. Re-run this installer:  bash scripts/install.sh"
fi

echo ""
divider
echo ""
echo "  Dashboard management:"
echo "    Update to latest version:  cd $PROJECT_DIR && bash scripts/update.sh"
echo "    nginx logs (errors):       sudo tail -f /var/log/nginx/demos-dashboard.error.log"
echo "    nginx logs (access):       sudo tail -f /var/log/nginx/demos-dashboard.access.log"
echo "    Restart nginx:             sudo systemctl restart nginx"
echo "    Test nginx config:         sudo nginx -t"
echo ""
echo "  If dashboard shows 'Cannot reach node':"
echo "    The DEMOS node must be running on this same server at port 53550."
echo "    Check: curl http://localhost:53550/api"
echo ""
echo "  Full guide: https://github.com/weudlll-cyber/demos-dashboard/blob/main/docs/VPS_SETUP.md"
echo ""
