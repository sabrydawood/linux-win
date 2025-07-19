#!/bin/bash

set -e

### 🛠️ Editable Configurations
SUB_DOMAIN="pma.futuresolutionsdev.com"
PHP_MY_ADMIN_DIR="/var/www/phpmyadmin"
EMAIL="kazouya25@gmail.com"

### 🔍 Detect PHP-FPM sock file automatically
echo "🔍 Detecting PHP-FPM .sock file..."
PHP_FPM_SOCK=$(find /run/php/ -type s -name "php*-fpm.sock" | sort | head -n 1)

if [[ -z "$PHP_FPM_SOCK" ]]; then
  echo "❌ No PHP-FPM socket found in /run/php/"
  exit 1
fi

echo "✅ Detected PHP-FPM socket: $PHP_FPM_SOCK"

### 🔍 Check Requirements
command -v nginx >/dev/null || { echo "❌ Nginx Not Found!"; exit 1; }
command -v php >/dev/null || { echo "❌ PHP Not Found!"; exit 1; }
command -v php-fpm >/dev/null || { echo "❌ PHP-FPM Not Found!"; exit 1; }

### 1. 📦 Download phpMyAdmin
echo "📦 Download phpMyAdmin..."
sudo mkdir -p "$PHP_MY_ADMIN_DIR"
cd /tmp
wget -q --show-progress https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz || { echo "❌ Failed to download phpMyAdmin"; exit 1; }
tar -xzf phpMyAdmin-latest-all-languages.tar.gz
sudo rm -rf "$PHP_MY_ADMIN_DIR"
sudo mv phpMyAdmin-*-all-languages "$PHP_MY_ADMIN_DIR"
sudo chown -R www-data:www-data "$PHP_MY_ADMIN_DIR"
rm phpMyAdmin-latest-all-languages.tar.gz

### 2. 📝 Create Nginx config
echo "📝 Create Nginx config..."
NGINX_CONF="/etc/nginx/sites-available/$SUB_DOMAIN"
sudo tee "$NGINX_CONF" > /dev/null <<EOF
server {
    listen 80;
    server_name $SUB_DOMAIN;

    root $PHP_MY_ADMIN_DIR;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:$PHP_FPM_SOCK;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

### 3. 🔗 Link Location To Active It
echo "🔗 Linking Location ..."
sudo ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

### 4. 🔐 Generate SSL From Let's Encrypt
echo "🔐 Generating SSL..."
sudo apt-get install -y certbot python3-certbot-nginx
sudo certbot --nginx --non-interactive --agree-tos -m "$EMAIL" -d "$SUB_DOMAIN"

### 5. ( Optional ) 🔒  Basic Auth Protection
read -p "🔒 Do You Want phpMyAdmin Basic Auth؟ (y/n): " protect
if [[ "$protect" == "y" ]]; then
    sudo apt install apache2-utils -y
    read -p "👤 Enter User Name: " auth_user
    sudo htpasswd -c /etc/nginx/.htpasswd "$auth_user"
    sudo sed -i "/location \/ {/a \        auth_basic \"Restricted\";\n        auth_basic_user_file /etc/nginx/.htpasswd;" "$NGINX_CONF"
    sudo systemctl reload nginx
    echo "✅ Protected phpMyAdmin with Basic Auth: $auth_user"
fi

echo "🎉 PhpMyAdmin Is Available Now At : https://$SUB_DOMAIN"
exit 0
