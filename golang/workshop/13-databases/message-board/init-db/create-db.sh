#!/bin/sh

echo "Creating database ..."

# == DB für Keycloak ==

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" \
-f /docker-entrypoint-initdb.d/create-db.sql-template \
-v app_db="$DB_NAME" \
-v app_schema="$DB_SCHEMA" \
-v app_user="$DB_USER" \
-v app_pass="$DB_PASSWORD"

