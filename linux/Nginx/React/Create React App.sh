#!/bin/bash

BASE_PATH="/home/shared/Work"
DEFAULT_DOMAIN="futuresolutionsdev.com"
SSL_EMAIL="kazsouya25@gmail.com"

CONFIG_DIR="$BASE_PATH/.apps"
mkdir -p "$CONFIG_DIR"

read -p "React App Name: " APP_NAME
read -p "Path (relative to $BASE_PATH): " REL_PATH
APP_PATH="$BASE_PATH/$REL_PATH"
read -p "Subdomain: " SUBDOMAIN
read -p "Git repo (leave blank if not available): " GIT_REPO

DOMAIN="$SUBDOMAIN.$DEFAULT_DOMAIN"

# Get available port
USED_PORTS_FILE="$BASE_PATH/used_ports.txt"
for port in {3000..3999}; do
  if ! grep -q "$port" "$USED_PORTS_FILE" 2>/dev/null && ! lsof -i:$port >/dev/null; then
    PORT=$port
    echo $PORT >> "$USED_PORTS_FILE"
    break
  fi
done

echo "✅ Using port: $PORT"

# Create app directory
mkdir -p "$APP_PATH"
cd "$APP_PATH"

if [[ -n "$GIT_REPO" ]]; then
  echo "📥 Cloning repo..."
  git clone "$GIT_REPO" . || {
    echo "❌ Failed to clone repo. Exiting."
    exit 1
  }
  npm install
  npm run build || {
    echo "❌ Build failed. Exiting."
    exit 1
  }
else
  echo "📝 Creating basic HTML page..."
  mkdir -p build
  cat <<EOF > build/index.html
<!DOCTYPE html>
<html>
<head><title>$APP_NAME</title></head>
<body><h1>$APP_NAME is running!</h1></body>
</html>
EOF
fi

# Install serve if not exists
if ! command -v serve &> /dev/null; then
  npm install -g serve
fi

# PM2
pm2 start "serve -s build -l $PORT" --name "$APP_NAME"
pm2 save
pm2 startup systemd -u root --hp /home/shared

# NGINX config
NGINX_FILE="/etc/nginx/sites-available/$DOMAIN"
cat <<EOF > $NGINX_FILE
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        try_files \$uri \$uri/ /index.html;
    }
}
EOF

ln -s $NGINX_FILE /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

# SSL
echo "🔐 Setting up SSL for $DOMAIN"
certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$SSL_EMAIL"
echo "0 0 * * * certbot renew --quiet" | crontab -

# UFW
echo "🛡️ UFW Protection Enabled"
ufw allow 'Nginx Full'
ufw allow OpenSSH
ufw enable

# Save config
cat <<EOF > "$CONFIG_DIR/$APP_NAME.conf"
APP_NAME=$APP_NAME
APP_PATH=$APP_PATH
DOMAIN=$DOMAIN
SUBDOMAIN=$SUBDOMAIN
PORT=$PORT
GIT_REPO=$GIT_REPO
EOF

echo "✅ React App $APP_NAME created and config saved to $CONFIG_DIR/$APP_NAME.conf"
echo "🌐 App is live at: https://$DOMAIN"
echo "▶️ To start: pm2 start $APP_NAME"
echo "⏹️ To stop: pm2 stop $APP_NAME"
echo "❌ To delete: pm2 delete $APP_NAME"

echo "🎉 Done."
