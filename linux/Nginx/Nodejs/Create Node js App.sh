#!/bin/bash

BASE_PATH="/home/shared/Work"
DEFAULT_DOMAIN="futuresolutionsdev.com"
SSL_EMAIL="kazouya25@gmail.com"

read -p "AppName: " APP_NAME
read -p "Path (relative to $BASE_PATH): " REL_PATH
read -p "Startup file (e.g. server.js): " STARTUP_FILE
STARTUP_FILE=${STARTUP_FILE:-index.js}
APP_PATH="$BASE_PATH/$REL_PATH"
read -p "Do you want a database? (y/n): " DB_CHOICE
read -p "Subdomain: " SUBDOMAIN

DOMAIN="$SUBDOMAIN.$DEFAULT_DOMAIN"
DB_NAME="$APP_NAME"

CONFIG_DIR="$BASE_PATH/.apps/Nodejs"
LOG_DIR="/var/log/nodejs"
USED_PORTS_FILE="$BASE_PATH/used_ports.txt"

mkdir -p "$APP_PATH" "$CONFIG_DIR" "$LOG_DIR"

# ✅ Get available port
for port in {3000..3999}; do
  if ! grep -q "$port" "$USED_PORTS_FILE" 2>/dev/null && ! lsof -i:$port >/dev/null; then
    PORT=$port
    echo $PORT >> "$USED_PORTS_FILE"
    break
  fi
done

echo "✅ Using port: $PORT"

# ✅ Initialize Node app
cd "$APP_PATH"
npm init -y
npm install express

# ✅ Create startup file with monitoring
cat <<EOF > "$STARTUP_FILE"
const express = require('express');
const os = require('os');
const { performance } = require('perf_hooks');

const app = express();
const PORT = process.env.PORT || $PORT;

app.use((req, res, next) => {
  const start = performance.now();
  res.on('finish', () => {
    const duration = (performance.now() - start).toFixed(2);
    console.log(\`[Performance] \${req.method} \${req.url} - \${duration} ms\`);
  });
  next();
});

setInterval(() => {
  const usage = process.memoryUsage();
  console.log(\`[Monitor] RAM: \${(usage.rss / 1024 / 1024).toFixed(2)} MB, Heap: \${(usage.heapUsed / 1024 / 1024).toFixed(2)} MB\`);
}, 60000);

app.get('/', (_, res) => res.send('Hello from $APP_NAME'));

app.listen(PORT, () => console.log(\` Server running on port \${PORT}\`));
EOF

# ✅ Create ecosystem.config.js
cat <<EOF > ecosystem.config.js
module.exports = {
  apps: [
    {
      name: "$APP_NAME",
      script: "$STARTUP_FILE",
      out_file: "$LOG_DIR/${APP_NAME}-out.log",
      error_file: "$LOG_DIR/${APP_NAME}-error.log",
      env: {
        NODE_ENV: "production",
        PORT: $PORT
      }
    }
  ]
};
EOF

# ✅ Optional DB
if [[ "$DB_CHOICE" == "y" ]]; then
  echo "Creating MariaDB database: $DB_NAME"
  mariadb -u root -p -e "CREATE DATABASE \\\`$DB_NAME\\\` CHARACTER SET utf8 COLLATE utf8mb3_unicode_ci;"
fi

# ✅ PM2 Setup
pm2 start ecosystem.config.js
pm2 save
pm2 startup systemd -u root --hp /home/shared

# ✅ Nginx config
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
    }
}
EOF

ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

# ✅ SSL via Certbot
echo "Setting up SSL for $DOMAIN"
certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$SSL_EMAIL"
echo "0 0 * * * certbot renew --quiet" | crontab -

# ✅ UFW Security
echo "UFW Protection Enabled"
ufw allow 'Nginx Full'
ufw allow OpenSSH
ufw --force enable

# ✅ Save config
cat <<EOF > "$CONFIG_DIR/$APP_NAME.conf"
APP_NAME=$APP_NAME
APP_PATH=$APP_PATH
DB_NAME=$DB_NAME
SUBDOMAIN=$SUBDOMAIN
DOMAIN=$DOMAIN
PORT=$PORT
EOF

echo "✅ Application $APP_NAME created and config saved to $CONFIG_DIR/$APP_NAME.conf"
echo " Accessible at: https://$DOMAIN"
echo " Logs: tail -f $LOG_DIR/${APP_NAME}-out.log"
echo "易 PM2 Monitoring: pm2 monit"
echo " Start app: pm2 start ecosystem.config.js"
echo " Stop app: pm2 stop $APP_NAME"
echo "️ Delete app: pm2 delete $APP_NAME"

echo "✅ Done."

exit 0
