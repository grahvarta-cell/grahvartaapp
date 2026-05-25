#!/bin/bash
# =============================================================
# AstroVaak — Full Deploy Script
# Run on your Hostinger VPS as root or sudo user
# Usage: bash deploy.sh
# =============================================================

set -e  # Exit on any error

APP_DIR="/var/www/astro-talk"
BACKEND_DIR="$APP_DIR/backend"
PREVIEW_DIR="$APP_DIR/preview"
NODE_VERSION="20"

echo "=============================="
echo "  AstroVaak Deploy Starting"
echo "=============================="

# ── 1. System packages ─────────────────────────────────────
echo "[1/8] Installing system packages..."
apt-get update -qq
apt-get install -y -qq curl git nginx certbot python3-certbot-nginx ufw postgresql postgresql-contrib

# ── 2. Node.js ─────────────────────────────────────────────
echo "[2/8] Installing Node.js $NODE_VERSION..."
if ! command -v node &>/dev/null; then
  curl -fsSL https://deb.nodesource.com/setup_$NODE_VERSION.x | bash -
  apt-get install -y nodejs
fi
npm install -g pm2

# ── 3. PostgreSQL setup ────────────────────────────────────
echo "[3/8] Setting up PostgreSQL..."
DB_NAME="astro_talk"
DB_USER="astro_user"
DB_PASS="Sis#1605"

sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1 || \
  sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"

sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" | grep -q 1 || \
  sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"

sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"

# ── 4. App directory ───────────────────────────────────────
echo "[4/8] Setting up app directories..."
mkdir -p $BACKEND_DIR $PREVIEW_DIR
mkdir -p $BACKEND_DIR/uploads $BACKEND_DIR/logs

# ── 5. npm install ─────────────────────────────────────────
echo "[5/8] Installing Node dependencies..."
cd $BACKEND_DIR
npm install --omit=dev

# ── 6. Run migrations ──────────────────────────────────────
echo "[6/8] Running database migrations..."
cd $BACKEND_DIR
node migrations/runAll.js
echo "  ✓ Migrations done"

# ── 7. PM2 ─────────────────────────────────────────────────
echo "[7/8] Starting/reloading PM2..."
cd $BACKEND_DIR
pm2 describe astro-talk-api > /dev/null 2>&1 && \
  pm2 reload ecosystem.config.js --env production || \
  pm2 start ecosystem.config.js --env production
pm2 save
pm2 startup systemd -u root --hp /root | tail -1 | bash || true

# ── 8. Nginx + SSL ─────────────────────────────────────────
echo "[8/8] Configuring Nginx..."
cp $BACKEND_DIR/deploy/nginx.conf /etc/nginx/sites-available/astrovaak
ln -sf /etc/nginx/sites-available/astrovaak /etc/nginx/sites-enabled/astrovaak
rm -f /etc/nginx/sites-enabled/default

nginx -t && systemctl reload nginx

# Firewall
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

echo ""
echo "=============================="
echo "  Deploy Complete!"
echo "=============================="
echo "  API:     https://api.astrovaak.online"
echo "  Preview: https://astrovaak.online"
echo "  PM2:     pm2 status"
echo "  Logs:    pm2 logs astro-talk-api"
echo ""
echo "  Next: run certbot for SSL"
echo "  certbot --nginx -d astrovaak.online -d www.astrovaak.online"
echo "  certbot --nginx -d api.astrovaak.online"
echo "=============================="
