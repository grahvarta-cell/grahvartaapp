# Grahvarta — Deployment Guide

## Architecture

| Component | Tech | URL |
|-----------|------|-----|
| User App | Flutter (Android) | — |
| Astrologer App | Flutter (Android) | — |
| Agent Onboarding App | Flutter (Android) | — |
| Astrologer Portal (Web) | React + Vite | https://www.grahvarta.com |
| Admin Portal (Web) | React + Vite | https://www.grahvarta.com/admin |
| Backend API | Node.js + Express | https://api.grahvarta.com |
| Database | PostgreSQL 15 | Internal (Docker) |
| Hosting | VPS (Docker Compose) | /opt/grahvarta |

---

## Server Stack

All services run via **Docker Compose** on a single VPS:

```
nginx          → reverse proxy + SSL (ports 80/443)
backend        → Node.js API (internal port 3000)
astrologer     → Astrologer Portal nginx (internal port 80)
admin          → Admin Portal nginx (internal port 80)
db             → PostgreSQL 15 (internal port 5432)
```

---

## First-Time VPS Setup

```bash
ssh root@YOUR_VPS_IP
cd /opt
bash <(curl -fsSL https://raw.githubusercontent.com/grahvarta-cell/grahvartaapp/main/deploy/deploy.sh)
```

The deploy script:
1. Installs Docker + Docker Compose
2. Clones the repo to `/opt/grahvarta`
3. Creates `.env` and `backend/.env` if missing
4. Issues Let's Encrypt SSL certs for `grahvarta.com` and `api.grahvarta.com`
5. Builds and starts all Docker services

---

## Redeploy After Code Changes

```bash
cd /opt/grahvarta
git pull origin main
docker compose up -d --build
docker compose restart nginx
```

### Rebuild only specific services

```bash
# Backend only
docker compose up -d --build backend
docker compose restart nginx

# Astrologer portal only
docker compose up -d --build astrologer
docker compose restart nginx

# Admin portal only
docker compose up -d --build admin
docker compose restart nginx
```

---

## Environment Files

### `/opt/grahvarta/.env` (Docker Compose variables)

```env
DOMAIN=grahvarta.com
API_DOMAIN=api.grahvarta.com
VITE_API_URL=https://api.grahvarta.com
DB_NAME=grahvarta_db
DB_USER=grahvarta_user
DB_PASSWORD=your_db_password
```

### `/opt/grahvarta/backend/.env` (Backend secrets)

```env
PORT=3000
NODE_ENV=production

DB_HOST=db
DB_PORT=5432
DB_NAME=grahvarta_db
DB_USER=grahvarta_user
DB_PASSWORD=your_db_password

JWT_SECRET=your_random_64_char_secret
JWT_EXPIRES_IN=30d

APP_URL=https://api.grahvarta.com
FRONTEND_URL=https://grahvarta.com
CORS_ORIGIN=https://grahvarta.com,https://www.grahvarta.com

RAZORPAY_KEY_ID=rzp_live_xxxx
RAZORPAY_KEY_SECRET=your_razorpay_secret

AGORA_APP_ID=your_agora_app_id
AGORA_APP_CERTIFICATE=your_agora_certificate

# Firebase Admin SDK — paste full service account JSON as single line
FIREBASE_SERVICE_ACCOUNT={"type":"service_account","project_id":"grahvarta-astrology",...}
FIREBASE_SERVICE_ACCOUNT_ASTROLOGER={"type":"service_account","project_id":"grahvarta-astrology",...}

UPLOAD_DIR=./uploads
MAX_FILE_SIZE=10485760
```

---

## Database

### Connect to DB

```bash
docker compose exec db psql -U grahvarta_user -d grahvarta_db
```

### Run migrations manually

```bash
docker compose exec backend node migrations/runAll.js
```

Migrations run automatically on backend startup. Each migration runs **exactly once** (tracked in `_migrations` table).

### Backup

```bash
docker compose exec db pg_dump -U grahvarta_user grahvarta_db > backup_$(date +%Y%m%d).sql
```

### Restore

```bash
cat backup.sql | docker compose exec -T db psql -U grahvarta_user -d grahvarta_db
```

---

## Flutter App Builds

### Prerequisites

- Flutter SDK (latest stable)
- Android Studio + SDK API 36 + NDK `28.2.13676358`
- Keystore files placed in each app's `android/` folder (not in git)

### User App

```bash
cd flutter_app
flutter pub get
flutter build apk --release --split-per-abi
# Output: build/app/outputs/flutter-apk/
```

### Astrologer App

```bash
cd astrologer_app
flutter pub get
flutter build apk --release --split-per-abi
```

### Agent Onboarding App

```bash
cd agent_onboarding_app
flutter pub get
flutter build apk --release --split-per-abi
```

### Keystore files (not in git — copy from secure storage)

| App | Keystore location |
|-----|-------------------|
| flutter_app | `android/upload-keystore.jks` |
| astrologer_app | `android/upload-keystore.jks` |
| agent_onboarding_app | `android/upload-keystore.jks` |

Each `android/key.properties` references the keystore:
```
storePassword=grahvarta2025
keyPassword=grahvarta2025
keyAlias=upload
storeFile=upload-keystore.jks
```

---

## Firebase Setup

Both Flutter apps use Firebase project **grahvarta-astrology**.

Required files (not in git):
- `flutter_app/android/app/google-services.json`
- `astrologer_app/android/app/google-services.json`
- `agent_onboarding_app/android/app/google-services.json`

### Push Notifications

FCM uses the Firebase Admin SDK on the backend.
- Generate a service account key from Firebase Console → Project Settings → Service Accounts
- Set as `FIREBASE_SERVICE_ACCOUNT` in `backend/.env`
- If astrologer app uses a separate project key, set `FIREBASE_SERVICE_ACCOUNT_ASTROLOGER`

### Troubleshooting FCM

```bash
# Check if tokens are registered
docker compose exec db psql -U grahvarta_user -d grahvarta_db \
  -c "SELECT user_id, app_type, LEFT(token,20) as token FROM push_tokens;"

# Clear stale tokens (users re-register on next app open)
docker compose exec db psql -U grahvarta_user -d grahvarta_db \
  -c "DELETE FROM push_tokens;"

# Check FCM errors in logs
docker compose logs backend --tail=100 | grep FCM
```

If you see `invalid_grant (Invalid JWT Signature)`:
```bash
# Sync server time
apt-get install -y ntpdate && ntpdate -u pool.ntp.org
docker compose restart backend
```

---

## SSL Certificates

Certificates are auto-issued via Let's Encrypt during first deploy.

### Manual renewal

```bash
certbot renew
docker compose restart nginx
```

Auto-renewal is set up via cron/systemd timer by the deploy script.

---

## Useful Commands

```bash
# View all running services
docker compose ps

# View backend logs (live)
docker compose logs -f backend

# View all logs
docker compose logs -f

# Restart a service
docker compose restart backend

# Shell into backend container
docker compose exec backend sh

# Shell into DB
docker compose exec db psql -U grahvarta_user -d grahvarta_db

# Full redeploy
git pull origin main && docker compose up -d --build && docker compose restart nginx
```

---

## Service URLs

| Service | URL |
|---------|-----|
| Astrologer Portal | https://www.grahvarta.com |
| Admin Portal | https://www.grahvarta.com/admin |
| Backend API | https://api.grahvarta.com |
| WebSocket | wss://api.grahvarta.com/socket.io |
