# Astro Talk - Deployment Guide (Hostinger VPS)

## Architecture
- **Frontend**: Flutter mobile app (iOS + Android)
- **Backend**: Node.js + Express API
- **Database**: PostgreSQL
- **Hosting**: Hostinger VPS

---

## 1. Hostinger VPS Setup

### Connect to your VPS
```bash
ssh root@YOUR_VPS_IP
```

### Install Node.js
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### Install PostgreSQL
```bash
sudo apt install postgresql postgresql-contrib -y
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

### Create database and user
```bash
sudo -u postgres psql
CREATE DATABASE astro_talk;
CREATE USER astro_user WITH ENCRYPTED PASSWORD 'your_strong_password';
GRANT ALL PRIVILEGES ON DATABASE astro_talk TO astro_user;
\q
```

### Install PM2 (process manager)
```bash
npm install -g pm2
```

### Install Nginx (reverse proxy)
```bash
sudo apt install nginx -y
```

---

## 2. Deploy Backend

### Upload files
```bash
# From local machine:
scp -r ./backend root@YOUR_VPS_IP:/var/www/astro-talk/
```

### Setup on VPS
```bash
cd /var/www/astro-talk
cp .env.example .env
nano .env  # Fill in your values

npm install
node migrations/run.js  # Run database migrations
pm2 start ecosystem.config.js --env production
pm2 save
pm2 startup
```

---

## 3. Nginx Configuration

```nginx
# /etc/nginx/sites-available/astro-talk
server {
    listen 80;
    server_name api.yourdomain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_cache_bypass $http_upgrade;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/astro-talk /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### Enable SSL (free with Let's Encrypt)
```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d api.yourdomain.com
```

---

## 4. Configure Flutter App

Update `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'https://api.yourdomain.com/api';
```

### Build Android APK
```bash
cd flutter_app
flutter pub get
flutter build apk --release
# APK at: build/app/outputs/flutter-apk/app-release.apk
```

### Build iOS
```bash
flutter build ios --release
# Open in Xcode for distribution
```

---

## 5. Database Backup (automate with cron)

```bash
# Add to crontab: crontab -e
0 2 * * * pg_dump -U astro_user astro_talk > /backups/astro_$(date +%Y%m%d).sql
```

---

## API Endpoints Reference

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | /api/auth/register | No | Register new user |
| POST | /api/auth/login | No | Login user |
| GET | /api/auth/profile | Yes | Get user profile |
| PUT | /api/auth/profile | Yes | Update profile |
| GET | /api/horoscope/:sign/:period | No | Get horoscope |
| GET | /api/horoscope/my | Yes | Get my horoscope |
| GET | /api/horoscope/signs | No | All zodiac signs |
| GET | /api/horoscope/compatibility/:s1/:s2 | Yes | Compatibility |
| GET | /api/dashboard | Yes | Dashboard data |
| GET | /api/birth-chart | Yes | Birth chart |
| GET | /api/transits | Yes | Current transits |
| GET | /api/audio | Yes | Sleep stories |
| GET | /api/courses | Yes | Courses list |
| GET | /api/affirmations | Yes | Weekly affirmations |

---

## Environment Variables (.env)

```
PORT=3000
NODE_ENV=production
DB_HOST=localhost
DB_PORT=5432
DB_NAME=astro_talk
DB_USER=astro_user
DB_PASSWORD=your_secure_password
JWT_SECRET=your_256bit_secret_key
JWT_EXPIRES_IN=30d
APP_URL=https://api.yourdomain.com
FRONTEND_URL=*
```
