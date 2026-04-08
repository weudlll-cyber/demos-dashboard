# VPS Setup Guide

Step-by-step instructions for deploying the DEMOS Node Dashboard on a Linux VPS.

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

**What the installer does automatically:**
1. Checks for / installs Node.js 20 LTS
2. Checks for / installs nginx
3. Runs `npm install` and `npm run build`
4. Copies `dist/` to `/var/www/demos-dashboard/`
5. Installs the nginx config to `/etc/nginx/sites-available/demos-dashboard`
6. Enables the site and reloads nginx

After it finishes, your dashboard is live at `http://YOUR-SERVER-IP`.

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

Once your domain's DNS A record points to the server's IP:

```bash
# Edit the nginx config
sudo nano /etc/nginx/sites-available/demos-dashboard
```

Change the `server_name` line to:

```nginx
server_name your-domain.com www.your-domain.com;
```

Then reload nginx:

```bash
sudo nginx -t && sudo systemctl reload nginx
```

---

## 7. Enable HTTPS with Let's Encrypt (Recommended)

```bash
# Install certbot
sudo apt-get install -y certbot python3-certbot-nginx

# Get a certificate (replaces HTTP with HTTPS automatically)
sudo certbot --nginx -d your-domain.com

# Certbot sets up auto-renewal. Test the renewal process:
sudo certbot renew --dry-run
```

After this, the dashboard is available at `https://your-domain.com`.

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
