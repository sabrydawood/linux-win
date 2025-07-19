#!/bin/bash

CONFIG_DIR="/home/shared/Work/.apps"

read -p "AppName to delete: " APP_NAME
CONFIG_FILE="$CONFIG_DIR/$APP_NAME.conf"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ Config file not found for $APP_NAME"
  exit 1
fi

# Get Config File
source "$CONFIG_FILE"

echo "⚠️ Deleting application: $APP_NAME"
echo "From path: $APP_PATH"
echo "Domain: $DOMAIN"
echo "Database: $DB_NAME"
echo "PM2 process: $APP_NAME"
echo "Port: $PORT"

read -p "Are you sure you want to proceed with deletion? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
  echo "❌ Operation cancelled."
  exit 1
fi

# Delete PM2
read -p "Delete PM2 process [$APP_NAME]? (y/n): " DELETE_PM2
if [[ "$DELETE_PM2" == "y" ]]; then
  echo "🛑 Stopping PM2 process..."
  pm2 delete "$APP_NAME"
  pm2 save
fi

# Delete App Directory
read -p "Delete application folder [$APP_PATH]? (y/n): " DELETE_FOLDER
if [[ "$DELETE_FOLDER" == "y" ]]; then
  echo "🗑️ Deleting folder..."
  rm -rf "$APP_PATH"
fi

# Delete Database
read -p "Drop database [$DB_NAME]? (y/n): " DELETE_DB
if [[ "$DELETE_DB" == "y" ]]; then
  echo "💣 Dropping database..."
  mysql -u root -p -e "DROP DATABASE IF EXISTS \`$DB_NAME\`;"
fi

# Delete NGINX
read -p "Remove NGINX config for domain [$DOMAIN]? (y/n): " DELETE_NGINX
if [[ "$DELETE_NGINX" == "y" ]]; then
  echo "🧹 Removing NGINX config..."
  rm -f /etc/nginx/sites-available/$DOMAIN
  rm -f /etc/nginx/sites-enabled/$DOMAIN
  nginx -t && systemctl reload nginx
fi

# Delete SSL
read -p "Delete SSL certificate for domain [$DOMAIN]? (y/n): " DELETE_SSL
if [[ "$DELETE_SSL" == "y" ]]; then
  echo "🔐 Deleting SSL certificate..."
  certbot delete --cert-name "$DOMAIN"
fi

# Delete
read -p "Delete app config file [$CONFIG_FILE]? (y/n): " DELETE_CONFIG
if [[ "$DELETE_CONFIG" == "y" ]]; then
  echo "🧾 Removing config file..."
  rm -f "$CONFIG_FILE"
fi

echo "✅ Deletion process completed (based on your choices)."

# Remove port from used_ports.txt
sed -i "/^$PORT$/d" /home/shared/Work/used_ports.txt

#  Remove Config File
rm -f "$CONFIG_FILE"

echo "✅ Port $PORT removed from used_ports.txt."

echo "🎉 Done."

exit 0