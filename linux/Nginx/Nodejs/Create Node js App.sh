#!/bin/bash

BASE_PATH="/home/shared/Work"
DEFAULT_DOMAIN="futuresolutionsdev.com"
SSL_EMAIL="kazsouya25@gmail.com"

CONFIG_DIR="$BASE_PATH/.apps/Nodejs"
mkdir -p "$CONFIG_DIR"

read -p "AppName: " APP_NAME
read -p "Path (relative to $BASE_PATH): " REL_PATH
APP_PATH="$BASE_PATH/$REL_PATH"
read -p "Do you want a database? (y/n): " DB_CHOICE
read -p "Subdomain: " SUBDOMAIN

DOMAIN="$SUBDOMAIN.$DEFAULT_DOMAIN"
DB_NAME="$APP_NAME"

# Get an available port
USED_PORTS_FILE="/home/shared/Work/used_ports.txt"
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
npm init -y
npm install express

cat <<EOF > index.js
const express = require('express');
const app = express();
app.get('/', (_, res) => res.send('Hello from $APP_NAME'));
app.listen($PORT, () => console.log('Server running on port $PORT'));
EOF

#  Database If needed
if [[ "$DB_CHOICE" == "y" ]]; then
  echo "Creating MariaDB database: $DB_NAME"
  mariadb -u root -p -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8 COLLATE utf8mb3_unicode_ci;"
fi

# PM2
pm2 start index.js --name "$APP_NAME"
pm2 save
pm2 startup systemd -u root --hp /home/shared

# nginx
cat <<EOF > /etc/nginx/sites-available/$DOMAIN
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

        # Custom headers ( Carful This May Duplicate If Your Code Returns Same Headers )
	      add_header Server "WorkStation.Server.Nova"; 
        }
}
EOF

ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

# SSL
echo "Setting up SSL for $DOMAIN"
certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$SSL_EMAIL"
echo "0 0 * * * certbot renew --quiet" | crontab -

#  ufw Protection
echo "Ufw Protection Enabled"
ufw allow 'Nginx Full'
ufw allow OpenSSH
ufw enable

#  Save config 
cat <<EOF > "$CONFIG_DIR/$APP_NAME.conf"
APP_NAME=$APP_NAME
APP_PATH=$APP_PATH
DB_NAME=$DB_NAME
SUBDOMAIN=$SUBDOMAIN
DOMAIN=$DOMAIN
PORT=$PORT
EOF

echo "✅ Application $APP_NAME created and config saved to $CONFIG_DIR/$APP_NAME.conf"
echo "✅ Application $APP_NAME is set up at https://$DOMAIN"
echo "✅ To start the application, run: pm2 start $CONFIG_DIR/$APP_NAME.conf"
echo "✅ To stop the application, run: pm2 stop $CONFIG_DIR/$APP_NAME.conf"
echo "✅ To delete the application, run: pm2 delete $CONFIG_DIR/$APP_NAME.conf"


echo "🎉 Done."

exit 0