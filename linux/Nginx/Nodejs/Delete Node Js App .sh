#!/bin/bash

CONFIG_DIR="/home/shared/Work/.apps/Nodejs"
USED_PORTS_FILE="/home/shared/Work/used_ports.txt"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

read -p "AppName to delete: " APP_NAME
CONFIG_FILE="$CONFIG_DIR/$APP_NAME.conf"

if [ ! -f "$CONFIG_FILE" ]; then
  echo -e "${RED}❌ Config file not found for $APP_NAME${NC}"
  exit 1
fi

# Load Config
source "$CONFIG_FILE"

echo -e "${YELLOW}⚠️ Deleting application: $APP_NAME${NC}"
echo "Path: $APP_PATH"
echo "Domain: $DOMAIN"
echo "Database: $DB_NAME"
echo "Port: $PORT"
echo "PM2 Process: $APP_NAME"

read -p "Are you sure you want to proceed with deletion? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
  echo -e "${RED}❌ Operation cancelled.${NC}"
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
  mariadb -u root -p -e "DROP DATABASE IF EXISTS \`$DB_NAME\`;"
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

# Delete Logs Files
read -p "Delete logs files ? (y/n): " DELETE_LOGS
if [[ "$DELETE_LOGS" == "y" ]]; then
  echo "🧹 Deleting logs files..."
  rm -rf "/home/shared/Logs/$APP_NAME"
fi

# Delete
read -p "Delete app config file [$CONFIG_FILE]? (y/n): " DELETE_CONFIG
if [[ "$DELETE_CONFIG" == "y" ]]; then
  echo "🧾 Removing config file..."
  rm -f "$CONFIG_FILE"
fi

# Remove port from used_ports.txt
sed -i "/^$PORT$/d" "$USED_PORTS_FILE"

#  Remove Config File
rm -f "$CONFIG_FILE"

echo -e "${GREEN}✅ Deletion completed for $APP_NAME (based on your choices).${NC}"
echo -e "${GREEN}🎉 Done.${NC}"
exit 0