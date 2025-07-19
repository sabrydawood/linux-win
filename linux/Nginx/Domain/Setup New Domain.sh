#!/bin/bash

set -e

### ────────────────────────────────
### 🔧 Functions
### ────────────────────────────────

ask() {
    local prompt="$1"
    local var_name="$2"
    local default_value="$3"
    read -p "$prompt [$default_value]: " input
    eval "$var_name='${input:-$default_value}'"
}

### ────────────────────────────────
### 🧠 Root Check
### ────────────────────────────────

if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root"
   exit 1
fi

### ────────────────────────────────
### 📥 User Inputs
### ────────────────────────────────

ask "🌐 Enter your domain name" DOMAIN "example.com"
ask "📁 Enter the document root for $DOMAIN" WEBROOT "/var/www/$DOMAIN"

### ────────────────────────────────
### 🌐 Nginx Installation
### ────────────────────────────────

if ! command -v nginx &> /dev/null; then
    echo "🌐 Nginx is not installed. Installing..."
    apt update && apt install -y nginx
fi

### ────────────────────────────────
### 🌍 Public IP + DNS Guidance
### ────────────────────────────────

SERVER_IP=$(curl -s ifconfig.me || echo "Unknown")
echo -e "\n🌍 Your server public IP is: $SERVER_IP"
echo "📌 Please configure your domain's DNS A record:"
echo "    Domain : $DOMAIN"
echo "    Type   : A"
echo "    Value  : $SERVER_IP"
read -p "⏳ Press Enter to continue once DNS has propagated..."

### ────────────────────────────────
### 📁 Web Root Setup
### ────────────────────────────────

mkdir -p "$WEBROOT"
chown -R www-data:www-data "$WEBROOT"
chmod -R 755 "$WEBROOT"

if [ ! -f "$WEBROOT/index.html" ]; then
    echo "<h1>Welcome to $DOMAIN</h1>" > "$WEBROOT/index.html"
fi

### ────────────────────────────────
### 📝 Nginx Configuration
### ────────────────────────────────

NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"

echo "📝 Creating Nginx config for $DOMAIN..."
cat > "$NGINX_CONF" <<EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    root $WEBROOT;
    index index.html index.htm index.php;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

# Enable site
if [ ! -L "/etc/nginx/sites-enabled/$DOMAIN" ]; then
    ln -s "$NGINX_CONF" /etc/nginx/sites-enabled/
fi

# Test and reload Nginx
echo "🔁 Testing Nginx config..."
nginx -t && systemctl restart nginx
echo "✅ Nginx is now configured for http://$DOMAIN"

### ────────────────────────────────
### 🔒 SSL via Certbot
### ────────────────────────────────

ask "🔐 Would you like to install an SSL certificate?" SSL_CHOICE "yes"
if [[ "$SSL_CHOICE" == "yes" ]]; then

    if ! command -v certbot &> /dev/null; then
        echo "📥 Installing Certbot..."
        apt update && apt install -y certbot python3-certbot-nginx
    fi

    echo "🔐 Requesting SSL certificate for $DOMAIN..."
    certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN"

    echo "🔁 Reloading Nginx with SSL config..."
    systemctl reload nginx

    echo "✅ SSL setup complete. Access your site at: https://$DOMAIN"

    echo "🔄 Testing automatic renewal..."
    certbot renew --dry-run
fi

### ────────────────────────────────
### ✅ Done
### ────────────────────────────────

echo -e "\n🎉 Setup complete!"
echo "🔗 Access your site at: http://$DOMAIN"
echo "🔗 Access your SSL site at: https://$DOMAIN"

exit 0
