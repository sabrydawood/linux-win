#!/bin/bash

set -e  # Exit on any error
set -o pipefail

BASE_PATH="/home/shared/Work"
DEFAULT_DOMAIN="futuresolutionsdev.com"
SSL_EMAIL="kazsouya25@gmail.com"
CONFIG_DIR="$BASE_PATH/.apps/React"
USED_PORTS_FILE="$BASE_PATH/used_ports.txt"

mkdir -p "$CONFIG_DIR"

# Variables for cleanup
CLEANUP_PORT=""
CLEANUP_PM2_NAME=""
CLEANUP_NGINX_FILE=""
CLEANUP_APP_PATH=""
CLEANUP_CONFIG_FILE=""

# Rollback logic
cleanup() {
  echo "⚠️ Rolling back due to error..."

  if [[ -n "$CLEANUP_NGINX_FILE" ]]; then
    echo "🧹 Removing NGINX config $CLEANUP_NGINX_FILE"
    rm -f "$CLEANUP_NGINX_FILE"
    rm -f "/etc/nginx/sites-enabled/$(basename "$CLEANUP_NGINX_FILE")"
    nginx -t && systemctl reload nginx || true
  fi

  if [[ -n "$CLEANUP_APP_PATH" && -d "$CLEANUP_APP_PATH" ]]; then
    echo "🧹 Deleting app folder $CLEANUP_APP_PATH"
    rm -rf "$CLEANUP_APP_PATH"
  fi

  if [[ -n "$CLEANUP_CONFIG_FILE" && -f "$CLEANUP_CONFIG_FILE" ]]; then
    echo "🧹 Removing config file $CLEANUP_CONFIG_FILE"
    rm -f "$CLEANUP_CONFIG_FILE"
  fi

  echo "🛑 Deployment failed and rollback complete."
}
trap cleanup ERR

# ========== INPUT ==========
read -p "React App Name: " APP_NAME
read -p "Path (relative to $BASE_PATH): " REL_PATH
APP_PATH="$BASE_PATH/$REL_PATH"
read -p "Subdomain: " SUBDOMAIN
read -p "Git repo (leave blank if not available): " GIT_REPO

# Check if HTTPS private repo and ask for PAT if needed
if [[ "$GIT_REPO" == https://* ]]; then
  read -p "Is this a private repo? (y/n): " IS_PRIVATE
  if [[ "$IS_PRIVATE" == "y" || "$IS_PRIVATE" == "Y" ]]; then
    echo "🔐 Enter your GitHub username and Personal Access Token (PAT)"
    read -p "GitHub Username: " GIT_USER
    read -s -p "Personal Access Token (input hidden): " GIT_PAT
    echo
    GIT_REPO=$(echo "$GIT_REPO" | sed "s#https://#https://$GIT_USER:$GIT_PAT@#")
  fi
elif [[ "$GIT_REPO" == git@* ]]; then
  echo "🔑 Make sure your SSH key is added to your GitHub account"
fi
if [[ -n "$GIT_REPO" ]]; then
  read -p "Branch name (leave blank for 'main'): " GIT_BRANCH
  GIT_BRANCH=${GIT_BRANCH:-main}
fi

DOMAIN="$SUBDOMAIN.$DEFAULT_DOMAIN"


# ========== CREATE FOLDER ==========
mkdir -p "$APP_PATH"
CLEANUP_APP_PATH="$APP_PATH"
cd "$APP_PATH"

# ========== CLONE OR CREATE ==========
if [[ -n "$GIT_REPO" ]]; then
  echo "📥 Cloning repo..."
  git clone -b "$GIT_BRANCH" --single-branch "$GIT_REPO" . || exit 1
  npm install
  npm run build || exit 1
else
  echo "📝 Creating basic HTML page..."
  mkdir -p dist
  cat <<EOF > dist/index.html
<!DOCTYPE html>
<html>
<head><title>$APP_NAME</title></head>
<body><h1>$APP_NAME is running!</h1></body>
</html>
EOF
fi

# Ask For BuildFolder name
read -p "Build Folder Name (default: dist): " BUILD_FOLDER
BUILD_FOLDER=${BUILD_FOLDER:-dist}


# ========== NGINX ==========
NGINX_FILE="/etc/nginx/sites-available/$DOMAIN"
cat <<EOF > $NGINX_FILE
server {
    listen 80;
    server_name $DOMAIN;

    root $APP_PATH/$BUILD_FOLDER;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
EOF

ln -s $NGINX_FILE /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
CLEANUP_NGINX_FILE="$NGINX_FILE"

# ========== SSL ==========
echo "🔐 Setting up SSL for $DOMAIN"
certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$SSL_EMAIL"
echo "0 0 * * * certbot renew --quiet" | crontab -

nginx -t && systemctl reload nginx

# ========== FIREWALL ==========
echo "🛡️ UFW Protection Enabled"
ufw allow 'Nginx Full'
ufw allow OpenSSH
ufw enable

# ========== SAVE CONFIG ==========
CONFIG_FILE="$CONFIG_DIR/$APP_NAME.conf"
cat <<EOF > "$CONFIG_FILE"
APP_NAME=$APP_NAME
APP_PATH=$APP_PATH
DOMAIN=$DOMAIN
SUBDOMAIN=$SUBDOMAIN
GIT_REPO=$GIT_REPO
EOF
CLEANUP_CONFIG_FILE="$CONFIG_FILE"

# ========== DONE ==========
trap - ERR  # Disable cleanup
echo "✅ React App $APP_NAME created and config saved to $CONFIG_FILE"
echo "🌐 App is live at: https://$DOMAIN"
echo "🎉 Done."

exit 0