#!/bin/sh
set -e

echo "Waiting for PostgreSQL..."
until node -e "
  const { Pool } = require('pg');
  const p = new Pool({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
  });
  p.query('SELECT 1').then(() => { p.end(); process.exit(0); }).catch(() => { p.end(); process.exit(1); });
" 2>/dev/null; do
  echo "  PostgreSQL not ready, retrying in 2s..."
  sleep 2
done
echo "  PostgreSQL is ready."

echo "Running migrations..."
node migrations/runAll.js

echo "Starting server..."
exec node server.js
