#!/bin/bash

CONFIG_DIR="/home/shared/Work/.apps/React"

read -p "React AppName to delete: " APP_NAME
CONFIG_FILE="$CONFIG_DIR/$APP_NAME.conf"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ Config file not found for $APP_NAME"
  exit 1
fi

# Load config variables
source "$CONFIG_FILE"

echo "⚠️ Deleting React application: $APP_NAME"
echo "From path: $APP_PATH"
echo "Domain: $DOMAIN"
echo "Repo: $GIT_REPO"

read -p "Are you sure you want to proceed with deletion? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
  echo "❌ Operation cancelled."
  exit 1
fi

# App folder
read -p "Delete application folder [$APP_PATH]? (y/n): " DELETE_FOLDER
if [[ "$DELETE_FOLDER" == "y" ]]; then
  echo "🗑️ Deleting folder..."
  rm -rf "$APP_PATH"
fi

# NGINX
read -p "Remove NGINX config for domain [$DOMAIN]? (y/n): " DELETE_NGINX
if [[ "$DELETE_NGINX" == "y" ]]; then
  echo "🧹 Removing NGINX config..."
  rm -f /etc/nginx/sites-available/$DOMAIN
  rm -f /etc/nginx/sites-enabled/$DOMAIN
  nginx -t && systemctl reload nginx
fi

# SSL
read -p "Delete SSL certificate for domain [$DOMAIN]? (y/n): " DELETE_SSL
if [[ "$DELETE_SSL" == "y" ]]; then
  echo "🔐 Deleting SSL certificate..."
  certbot delete --cert-name "$DOMAIN"
fi

# Config
read -p "Delete app config file [$CONFIG_FILE]? (y/n): " DELETE_CONFIG
if [[ "$DELETE_CONFIG" == "y" ]]; then
  echo "🧾 Removing config file..."
  rm -f "$CONFIG_FILE"
fi


echo "✅ Deletion completed for $APP_NAME (based on your choices)."
echo "🎉 Done."

exit 0
