#!/bin/bash
# =============================================================
# Grahvarta — Full Deploy Script
# Run on your Hostinger VPS as root or sudo user
# Usage: bash deploy.sh
# =============================================================

set -e  # Exit on any error

APP_DIR="/opt/grahvarta"
BACKEND_DIR="$APP_DIR/backend"
NODE_VERSION="20"

echo "=============================="
echo "  Grahvarta Deploy Starting"
echo "=============================="

# ── 1. System packages ─────────────────────────────────────
echo "[1/7] Installing system packages..."
apt-get update -qq
apt-get install -y -qq curl git nginx certbot python3-certbot-nginx ufw postgresql postgresql-contrib

# ── 2. Node.js ─────────────────────────────────────────────
echo "[2/7] Installing Node.js $NODE_VERSION..."
if ! command -v node &>/dev/null; then
  curl -fsSL https://deb.nodesource.com/setup_$NODE_VERSION.x | bash -
  apt-get install -y nodejs
fi
npm install -g pm2

# ── 3. PostgreSQL setup ────────────────────────────────────
echo "[3/7] Setting up PostgreSQL..."
DB_NAME="grahvarta_db"
DB_USER="grahvarta_user"
DB_PASS="${DB_PASSWORD:-}"

if [ -z "$DB_PASS" ]; then
  echo "ERROR: Set DB_PASSWORD environment variable before running this script."
  exit 1
fi

# Change pg_hba.conf to use md5 auth
sed -i 's/scram-sha-256/md5/g' /etc/postgresql/*/main/pg_hba.conf
systemctl reload postgresql

sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1 || \
  sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"

sudo -u postgres psql -c "ALTER USER $DB_USER WITH PASSWORD '$DB_PASS';"

sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" | grep -q 1 || \
  sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"

sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
sudo -u postgres psql -c "ALTER DATABASE $DB_NAME OWNER TO $DB_USER;"

# ── 4. App directory ───────────────────────────────────────
echo "[4/7] Setting up app directories..."
mkdir -p $BACKEND_DIR/uploads $BACKEND_DIR/logs

# ── 5. npm install ─────────────────────────────────────────
echo "[5/7] Installing Node dependencies..."
cd $BACKEND_DIR
npm install --omit=dev

# ── 6. Run migrations ──────────────────────────────────────
echo "[6/7] Running database migrations..."
node migrations/runAll.js
echo "  ✓ Migrations done"

# ── 7. PM2 ─────────────────────────────────────────────────
echo "[7/7] Starting/reloading PM2..."
pm2 describe grahvarta-api > /dev/null 2>&1 && \
  pm2 reload ecosystem.config.js --env production || \
  pm2 start ecosystem.config.js --env production
pm2 save
pm2 startup systemd -u root --hp /root | tail -1 | bash || true

# ── Nginx + SSL ─────────────────────────────────────────
echo "Configuring Nginx..."
cp $BACKEND_DIR/deploy/nginx.conf /etc/nginx/sites-available/grahvarta
ln -sf /etc/nginx/sites-available/grahvarta /etc/nginx/sites-enabled/grahvarta
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
echo "  API:  https://api.grahvarta.com"
echo "  PM2:  pm2 status"
echo "  Logs: pm2 logs grahvarta-api"
echo ""
echo "  Next: run certbot for SSL"
echo "  certbot --nginx -d api.grahvarta.com"
echo "=============================="
