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
sudo git clone https://github.com/your-username/demos-dashboard.git
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
