# VPS Setup Guide

Step-by-step guide for deploying the DEMOS Node Dashboard on a Linux VPS.

---

## Quick Start — From zero to running in ~5 minutes

This is everything you need. Run these commands on your VPS (Ubuntu 22.04/24.04):

```bash
# 1. Install base tools
sudo apt-get update && sudo apt-get install -y git curl rsync

# 2. Clone the repository
cd /opt && sudo git clone https://github.com/weudlll-cyber/demos-dashboard.git
sudo chown -R $USER:$USER /opt/demos-dashboard
cd /opt/demos-dashboard

# 3. Run the interactive installer
#    It will ask for your domain name and email, then handle everything:
#    Node.js, nginx, building, deploying, and optionally HTTPS.
bash scripts/install.sh
```

The installer prints your live URL at the end.

**To update the dashboard** after any code change:
```bash
cd /opt/demos-dashboard && bash scripts/update.sh
```

---

> **The sections below explain what the installer does and how to do each
> step manually if needed.** If the Quick Start above worked, you are done.

---

## Assumptions

- **OS:** Ubuntu 22.04 or 24.04 LTS (other Debian-based distros work too)
- **Access:** root or a sudo user
- **DEMOS node:** already running on the same server at `localhost:53550`
- **Ports:** 80 (and optionally 443) reachable from the internet

---

## 1. Prepare the Server

```bash
# Update system packages
sudo apt-get update && sudo apt-get upgrade -y

# Install required tools
sudo apt-get install -y git curl rsync
```

---

## 2. Install Node.js

The installer script handles this automatically, but you can also do it manually:

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify
node -v   # should print v20.x.x
npm -v    # should print 10.x.x or higher
```

---

## 3. Clone the Repository

```bash
sudo mkdir -p /opt
cd /opt
sudo git clone https://github.com/weudlll-cyber/demos-dashboard.git
sudo chown -R $USER:$USER /opt/demos-dashboard
cd /opt/demos-dashboard
```

---

## 4. Run the Installer

```bash
bash scripts/install.sh
```

The installer is **interactive** — it will ask you two questions:

| Question | What to enter |
|----------|--------------|
| Domain name | Your domain (e.g. `demo.example.com`), or press ENTER to skip (IP-only access) |
| Email for HTTPS | Your email address for Let's Encrypt alerts, or press ENTER to skip HTTPS |

If you provide both a domain and an email, the installer **automatically**:
1. Installs Node.js 20 LTS (if not present) and nginx (if not present)
2. Builds the dashboard (`npm install` + `npm run build`)
3. Deploys `dist/` to `/var/www/demos-dashboard/` with secure permissions
4. Installs and configures nginx with your domain
5. Runs certbot to obtain a free HTTPS certificate from Let's Encrypt
6. Adds the hardened HTTPS server block and enables the HTTP→HTTPS redirect

The final line it prints is your live URL.

---

## 5. Verify the Installation

```bash
# Check nginx is running
sudo systemctl status nginx

# Check the web root has files
ls -la /var/www/demos-dashboard/

# Test from the command line
curl -I http://localhost
```

Open `http://YOUR-SERVER-IP` in a browser. You should see the dashboard. If the DEMOS node is running, data will start appearing within 3 seconds.

---

## 6. Configure a Domain (Optional)

> **If you ran the installer and provided a domain, this is already done.**

If you want to add or change the domain later:

```bash
sudo nano /etc/nginx/sites-available/demos-dashboard
```

Change the `server_name` line to your domain, then reload:

```bash
sudo nginx -t && sudo systemctl reload nginx
```

---

## 7. Enable HTTPS with Let's Encrypt

> **If you ran the installer and provided an email, this is already done.**

HTTPS encrypts all traffic between the browser and the server. Without it, API responses travel in cleartext.

### Prerequisites

- Your domain's **DNS A record must point to this server's IP**.
- Port 80 must be reachable (nginx must be running).
- Verify DNS: `dig +short your-domain.com` — should return this server's IP.

### Option A — Automatic (recommended)

Re-run the installer and provide your domain and email when asked. It handles everything.

```bash
bash scripts/install.sh
```

### Option B — Manual (if you already have a domain configured)

```bash
# Step 1: Obtain the certificate (does NOT touch nginx)
sudo apt-get install -y certbot
sudo certbot certonly --webroot -w /var/www/html \
     -d your-domain.com --email your@email.com --agree-tos

# Step 2: Activate the HTTPS server block and redirect
bash scripts/https-activate.sh your-domain.com
```

`https-activate.sh` appends the hardened HTTPS server block, enables the HTTP→HTTPS redirect, and reloads nginx — no manual file editing needed.

### After HTTPS is working

Once you confirm `https://your-domain.com` loads correctly, increase the HSTS duration from 5 minutes to 1 year:

```bash
sudo sed -i 's/max-age=300/max-age=31536000/' /etc/nginx/sites-available/demos-dashboard
sudo nginx -t && sudo systemctl reload nginx
```

Then verify your headers score an A or A+ at **https://securityheaders.com**.

### Auto-renewal

Certbot installs a systemd timer that renews certificates automatically every ~60 days. Test it at any time:

```bash
sudo certbot renew --dry-run
```

---

## 8. Configure the Firewall (UFW)

```bash
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'   # opens ports 80 and 443
sudo ufw enable
sudo ufw status
```

---

## 9. SSH Hardening

Reducing the SSH attack surface is one of the most impactful things you can do on a public VPS.

### 9.1 Key-based authentication only

On your **local machine**, generate an SSH key if you don't already have one:

```bash
ssh-keygen -t ed25519 -C "your-email@example.com"
```

Copy your public key to the server:

```bash
ssh-copy-id your-user@your-vps-ip
```

Then on the **VPS**, lock down the SSH daemon:

```bash
sudo nano /etc/ssh/sshd_config
```

Set or confirm these values:

```
# Disable root login completely
PermitRootLogin no

# Require SSH key — password logins are forbidden
PasswordAuthentication no
ChallengeResponseAuthentication no

# Only allow your specific user (optional but recommended)
AllowUsers your-user
```

Reload SSH (do NOT close your existing session first — open a second terminal to verify
the new key login works before reloading, to avoid locking yourself out):

```bash
sudo sshd -t          # syntax check — must return no errors
sudo systemctl reload sshd
```

### 9.2 Install and configure fail2ban

fail2ban watches log files and automatically bans IPs that show brute-force patterns.

```bash
sudo apt install -y fail2ban
```

Create a local override file (never edit the default `jail.conf` — it gets overwritten on upgrades):

```bash
sudo nano /etc/fail2ban/jail.local
```

Paste the following:

```ini
[DEFAULT]
# Ban IPs for 1 hour after 5 failures within a 10-minute window
bantime  = 3600
findtime = 600
maxretry = 5

# Send ban notifications to the local syslog
destemail = root@localhost
action = %(action_mw)s

[sshd]
enabled  = true
port     = ssh
logpath  = %(sshd_log)s
backend  = %(sshd_backend)s

[nginx-http-auth]
enabled  = true

[nginx-limit-req]
# Catches IPs that repeatedly hit the nginx rate-limit (429 responses)
enabled  = true
filter   = nginx-limit-req
logpath  = /var/log/nginx/error.log
maxretry = 10
```

Enable and start fail2ban:

```bash
sudo systemctl enable --now fail2ban
sudo fail2ban-client status          # verify both jails are active
sudo fail2ban-client status sshd     # check the SSH jail specifically
```

### 9.3 Verify your hardening (quick checklist)

| Check | Command |
|-------|---------|
| Root login disabled | `sudo sshd -T \| grep permitrootlogin` → must say `no` |
| Password auth off | `sudo sshd -T \| grep passwordauthentication` → must say `no` |
| fail2ban SSH jail active | `sudo fail2ban-client status sshd` |
| fail2ban nginx jail active | `sudo fail2ban-client status nginx-limit-req` |
| UFW status | `sudo ufw status verbose` |

---

## Updating the Dashboard

After you push new changes to GitHub, pull and redeploy on the VPS with a single command:

```bash
cd /opt/demos-dashboard
bash scripts/update.sh
```

The update script:
1. Runs `git pull origin main`
2. Runs `npm install` (picks up any dependency changes)
3. Runs `npm run build`
4. Syncs `dist/` to `/var/www/demos-dashboard/`
5. Reloads nginx

---

## Directory Layout on the VPS

```
/opt/demos-dashboard/              ← git repo (source code + scripts)
/var/www/demos-dashboard/          ← compiled static files (served by nginx)
/etc/nginx/sites-available/demos-dashboard   ← nginx config
/etc/nginx/sites-enabled/demos-dashboard     ← symlink (enables the site)
/var/log/nginx/demos-dashboard.access.log    ← access log
/var/log/nginx/demos-dashboard.error.log     ← error log
```

---

## Troubleshooting

| Problem | What to check |
|---------|---------------|
| Dashboard loads but shows "Cannot reach node" | `curl http://localhost:53550/api` — is the DEMOS node running? |
| Blank page or 404 | `ls /var/www/demos-dashboard/` — are build files present? |
| nginx fails to start | `sudo nginx -t` — read the config error |
| Port 80 blocked externally | `sudo ufw status` — is `Nginx Full` allowed? |
| Build fails with "node: not found" | `node -v` — is Node.js ≥ 18 installed? |
| Permission denied on web root | `sudo chown -R www-data:www-data /var/www/demos-dashboard` |

---

## Alternative: Systemd Service (without nginx)

If you prefer not to configure nginx, you can run `vite preview` as a systemd service on port 4173. See `scripts/demos-dashboard.service` for instructions. This is **not recommended for production** but is useful for quick testing.
