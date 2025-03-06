#!/bin/bash
ask() {
    local prompt="$1"
    local var_name="$2"
    local default_value="$3"
    read -p "$prompt [$default_value]: " input
    eval "$var_name='${input:-$default_value}'"
}
# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi
# Ask for domain name
ask "Enter your domain name" DOMAIN "example.com"
# Ask for web root directory
ask "Enter the document root for $DOMAIN" WEBROOT "/var/www/$DOMAIN"
# Install Nginx if not installed
if ! command -v nginx &> /dev/null; then
    echo "Nginx is not installed. Installing..."
    apt update && apt install -y nginx
fi

# Get public IP
SERVER_IP=$(curl -s ifconfig.me)
echo "Your server public IP is: $SERVER_IP"

# Display DNS setup instructions
echo "Please configure the following DNS record for your domain:"
echo "Type: A"
echo "Name: @ (or www if using a subdomain)"
echo "Value: $SERVER_IP"
echo "Wait for DNS propagation before proceeding."

# Create web root directory
mkdir -p "$WEBROOT"
chown -R www-data:www-data "$WEBROOT"
chmod -R 755 "$WEBROOT"

echo "<h1>Welcome to $DOMAIN</h1>" > "$WEBROOT/index.html"

# Create Nginx configuration file
NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"
echo "Creating Nginx configuration for $DOMAIN..."
cat > "$NGINX_CONF" <<EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    root $WEBROOT;
    index index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

# Enable configuration
ln -s "$NGINX_CONF" /etc/nginx/sites-enabled/

# Test Nginx configuration
nginx -t && systemctl reload nginx

echo "Nginx is now configured for $DOMAIN"

# Ask for SSL setup
ask "Would you like to install an SSL certificate? (yes/no)" SSL_CHOICE "yes"
if [[ "$SSL_CHOICE" == "yes" ]]; then
    # Install Certbot if not installed
    if ! command -v certbot &> /dev/null; then
        echo "Installing Certbot..."
        apt update && apt install -y certbot python3-certbot-nginx
    fi
    
    # Obtain SSL certificate
    certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN"
    
    # Verify SSL setup
    systemctl reload nginx
    echo "SSL setup complete. Your site is now accessible via HTTPS."
    
    # Enable auto-renewal
    certbot renew --dry-run
fi

echo "Setup complete!"
