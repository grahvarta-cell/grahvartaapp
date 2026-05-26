#!/bin/bash
# =============================================================
# Grahvarta — Docker Deployment Script
# Run as root (or sudo) directly on the VPS:
#   bash deploy.sh
#
# What it does:
#   1. Installs Docker, Docker Compose, Certbot
#   2. Clones / updates the repository
#   3. Creates .env and backend/.env if they don't exist
#   4. Issues Let's Encrypt SSL certificates (first run only)
#   5. Builds and starts all services via docker compose
#   6. Sets up auto-renewal for SSL certs
#
# Subsequent deploys: just run again — it's fully idempotent.
# =============================================================

set -e

# ── ⚠  Edit before first deploy ─────────────────────────────
REPO_URL="https://github.com/grahvarta-cell/grahvartaapp.git"
BRANCH="main"
DB_PASSWORD="Sis#1605"
ADMIN_EMAIL="admin@grahvarta.com"
# ─────────────────────────────────────────────────────────────

DOMAIN="grahvarta.com"
API_DOMAIN="api.grahvarta.com"
APP_DIR="/opt/grahvarta"

echo "=============================="
echo "  Grahvarta Docker Deploy"
echo "=============================="

# ── 1. Docker ─────────────────────────────────────────────────────────────
echo "[1/6] Installing Docker..."
if ! command -v docker &>/dev/null; then
  curl -fsSL https://get.docker.com | bash
fi
if ! command -v docker &>/dev/null; then
  echo "ERROR: Docker installation failed." && exit 1
fi

# Docker Compose plugin (included with modern Docker Engine)
docker compose version &>/dev/null || {
  apt-get install -y docker-compose-plugin
}

# ── 2. Certbot ────────────────────────────────────────────────────────────
echo "[2/6] Installing Certbot..."
apt-get update -qq
apt-get install -y -qq certbot ufw

# ── 3. Clone / update repo ────────────────────────────────────────────────
echo "[3/6] Fetching latest code..."
if [ -d "$APP_DIR/.git" ]; then
  cd "$APP_DIR"
  git fetch origin
  git reset --hard "origin/$BRANCH"
else
  rm -rf "$APP_DIR"
  git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$APP_DIR"
  cd "$APP_DIR"
fi

# ── 4. Create .env files (skipped if they already exist) ──────────────────
echo "[4/6] Setting up environment files..."

# Root .env (for docker-compose)
if [ ! -f "$APP_DIR/.env" ]; then
  cat > "$APP_DIR/.env" << ENV
DOMAIN=$DOMAIN
API_DOMAIN=$API_DOMAIN
VITE_API_URL=https://$API_DOMAIN
DB_NAME=grahvarta_db
DB_USER=grahvarta_user
DB_PASSWORD=$DB_PASSWORD
ENV
  echo "  ✓ Created .env"
else
  echo "  ✓ .env already exists — skipping"
fi

# Backend .env (for the Node.js container)
if [ ! -f "$APP_DIR/backend/.env" ]; then
  cat > "$APP_DIR/backend/.env" << ENV
PORT=3000
NODE_ENV=production

# Database — DB_HOST is overridden to 'db' by docker-compose
DB_HOST=db
DB_PORT=5432
DB_NAME=grahvarta_db
DB_USER=grahvarta_user
DB_PASSWORD=$DB_PASSWORD

# JWT — replace with a random 64-char string
JWT_SECRET=CHANGE_ME_MIN_32_CHARS_RANDOM_STRING
JWT_EXPIRES_IN=30d

# URLs
APP_URL=https://$API_DOMAIN
FRONTEND_URL=https://$DOMAIN
CORS_ORIGIN=https://$DOMAIN,https://www.$DOMAIN

# Razorpay
RAZORPAY_KEY_ID=rzp_live_xxxx
RAZORPAY_KEY_SECRET=your_razorpay_secret

# Agora (voice/video)
AGORA_APP_ID=your_agora_app_id
AGORA_APP_CERTIFICATE=your_agora_certificate

# Firebase Admin (FCM) — paste full service account JSON as one line
# User app (com.grahvarta.user) service account key
FIREBASE_SERVICE_ACCOUNT={"type":"service_account","project_id":"..."}
# Astrologer app (com.grahvartaastrology.app) service account key
FIREBASE_SERVICE_ACCOUNT_ASTROLOGER={"type":"service_account","project_id":"..."}

# Uploads
UPLOAD_DIR=./uploads
MAX_FILE_SIZE=10485760
ENV
  echo "  ⚠  Created backend/.env — IMPORTANT: fill in secrets before continuing!"
  echo "      Edit $APP_DIR/backend/.env, then re-run this script."
  echo ""
  read -r -p "Have you filled in the secrets? [y/N]: " confirm
  [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborting. Re-run after editing the .env file."; exit 1; }
else
  echo "  ✓ backend/.env already exists — skipping"
fi

# ── 5. SSL Certificates ───────────────────────────────────────────────────
echo "[5/6] Checking SSL certificates..."

CERT_PATH="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
API_CERT_PATH="/etc/letsencrypt/live/$API_DOMAIN/fullchain.pem"

if [ ! -f "$CERT_PATH" ] || [ ! -f "$API_CERT_PATH" ]; then
  echo "  → No certs found; running HTTP bootstrap for certbot..."

  # Start a temporary nginx container for the ACME challenge
  docker run -d --name grahvarta-certbot-init \
    -p 80:80 \
    -v "$APP_DIR/docker/nginx-init.conf:/etc/nginx/conf.d/default.conf:ro" \
    nginx:alpine

  sleep 3

  # Issue certs using webroot (nginx serves /.well-known/...)
  certbot certonly --webroot \
    -w /var/www/html \
    -d "$DOMAIN" -d "www.$DOMAIN" \
    --non-interactive --agree-tos -m "$ADMIN_EMAIL" \
    --pre-hook "docker exec grahvarta-certbot-init nginx -s reload || true" \
    2>&1 || certbot certonly --standalone \
              -d "$DOMAIN" -d "www.$DOMAIN" \
              --non-interactive --agree-tos -m "$ADMIN_EMAIL" \
              --pre-hook "docker rm -f grahvarta-certbot-init 2>/dev/null || true" \
              --post-hook ""

  certbot certonly --standalone \
    -d "$API_DOMAIN" \
    --non-interactive --agree-tos -m "$ADMIN_EMAIL" \
    --pre-hook "docker rm -f grahvarta-certbot-init 2>/dev/null || true" || true

  docker rm -f grahvarta-certbot-init 2>/dev/null || true
  echo "  ✓ SSL certificates issued"
else
  echo "  ✓ SSL certificates already present"
fi

# ── 6. Docker Compose ─────────────────────────────────────────────────────
echo "[6/6] Building and starting services..."
cd "$APP_DIR"

docker compose pull --quiet nginx 2>/dev/null || true
docker compose build --parallel

docker compose up -d

echo ""
echo "  Waiting for services to be healthy..."
sleep 10
docker compose ps

# ── Firewall ──────────────────────────────────────────────────────────────
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# ── Auto-renew SSL certs ──────────────────────────────────────────────────
# Certbot auto-renew: stop nginx, renew, restart
RENEW_HOOK_DIR="/etc/letsencrypt/renewal-hooks/deploy"
mkdir -p "$RENEW_HOOK_DIR"
cat > "$RENEW_HOOK_DIR/restart-nginx.sh" << 'HOOK'
#!/bin/bash
cd /opt/grahvarta
docker compose restart nginx
HOOK
chmod +x "$RENEW_HOOK_DIR/restart-nginx.sh"

# Ensure certbot timer is active (or add cron as fallback)
systemctl enable --now certbot.timer 2>/dev/null || \
  (crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet") | crontab -

echo ""
echo "=============================="
echo "  Deploy Complete!"
echo "=============================="
echo ""
echo "  Astrologer:  https://$DOMAIN"
echo "  Admin:       https://$DOMAIN/admin"
echo "  API:         https://$API_DOMAIN"
echo ""
echo "  Manage:"
echo "    docker compose ps"
echo "    docker compose logs -f backend"
echo "    docker compose restart nginx"
echo "    docker compose up -d --build   # redeploy after code changes"
echo "=============================="
