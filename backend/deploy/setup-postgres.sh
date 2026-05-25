#!/bin/bash
# Run this ONCE on the server as root to create the database and user.
# Usage: sudo bash setup-postgres.sh

set -e

DB_NAME="astro_talk"
DB_USER="astro_user"
DB_PASSWORD="Sis#1605"   # change this or source from a secrets file

echo "==> Setting up PostgreSQL..."

# Install PostgreSQL if not present
if ! command -v psql &>/dev/null; then
  apt-get update -y
  apt-get install -y postgresql postgresql-contrib
fi

systemctl enable postgresql
systemctl start postgresql

# Create role and database (idempotent)
sudo -u postgres psql -v ON_ERROR_STOP=1 <<SQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$DB_USER') THEN
    CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASSWORD';
  END IF;
END
\$\$;

SELECT 'CREATE DATABASE $DB_NAME OWNER $DB_USER'
  WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$DB_NAME')\gexec
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
SQL

echo "==> PostgreSQL setup complete."
echo "    Database : $DB_NAME"
echo "    User     : $DB_USER"
