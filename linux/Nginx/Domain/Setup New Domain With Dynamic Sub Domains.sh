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
    echo "❌ This script must be run as root"
    exit 1
fi

# Input
ask "Enter your primary domain (e.g., example.com)" DOMAIN "example.com"
ask "Enter subdomains (comma-separated, e.g., app, blog, api) or leave blank for none" SUBDOMAINS ""

# Install Nginx if not installed
if ! command -v nginx &> /dev/null; then
    echo "🌐 Nginx is not installed. Installing..."
    apt update && apt install -y nginx
fi

# Get public IP
SERVER_IP=$(curl -s ifconfig.me)
echo "🌍 Your server public IP is: $SERVER_IP"

# DNS Instructions
echo -e "\n📌 Please configure the following DNS records:"
echo "Type: A"
echo "Name: @ and your subdomains (if any)"
echo "Value: $SERVER_IP"
echo "⏳ Wait for DNS propagation before proceeding."

# Function to configure Nginx
configure_nginx() {
    local domain_name="$1"
    local webroot="/var/www/$domain_name"
    local config_file="/etc/nginx/sites-available/$domain_name"

    echo "⚙️ Configuring Nginx for $domain_name..."

    # Create web root
    mkdir -p "$webroot"
    chown -R www-data:www-data "$webroot"
    chmod -R 755 "$webroot"

    # Create index.html if not exists
    if [[ ! -f "$webroot/index.html" ]]; then
        echo "<h1>Welcome to $domain_name</h1>" > "$webroot/index.html"
    fi

    # Nginx config
    cat > "$config_file" <<EOF
server {
    listen 80;
    server_name $domain_name;

    root $webroot;
    index index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

    # Enable config
    ln -sf "$config_file" "/etc/nginx/sites-enabled/$domain_name"
    echo "✅ Nginx configuration created for $domain_name."
}

# Configure primary domain
configure_nginx "$DOMAIN"

# Configure subdomains
if [[ -n "$SUBDOMAINS" ]]; then
    IFS=',' read -ra SUBDOMAIN_LIST <<< "$SUBDOMAINS"
    for sub in "${SUBDOMAIN_LIST[@]}"; do
        cleaned_sub=$(echo "${sub}" | xargs)
        subdomain="$cleaned_sub.$DOMAIN"
        configure_nginx "$subdomain"
    done
fi

# Reload Nginx
nginx -t && systemctl reload nginx
echo "🔄 Nginx reloaded."

# SSL setup
ask "Would you like to install an SSL certificate? (yes/no)" SSL_CHOICE "yes"
if [[ "$SSL_CHOICE" == "yes" ]]; then
    # Install Certbot if not installed
    if ! command -v certbot &> /dev/null; then
        echo "🔐 Installing Certbot..."
        apt update && apt install -y certbot python3-certbot-nginx
    fi

    # Prepare domain list
    DOMAIN_LIST="-d $DOMAIN"
    if [[ -n "$SUBDOMAINS" ]]; then
        for sub in "${SUBDOMAIN_LIST[@]}"; do
            cleaned_sub=$(echo "${sub}" | xargs)
            DOMAIN_LIST+=" -d ${cleaned_sub}.$DOMAIN"
        done
    fi

    CERTBOT_EMAIL="admin@$DOMAIN"
    certbot --nginx --non-interactive --agree-tos -m "$CERTBOT_EMAIL" $DOMAIN_LIST

    # Reload nginx again
    systemctl reload nginx
    echo "🔒 SSL setup complete!"

    # Test auto-renew
    certbot renew --dry-run
fi

# Output success links
echo -e "\n🎉 Setup complete!"
echo "🌐 Main Domain: https://$DOMAIN"
if [[ -n "$SUBDOMAINS" ]]; then
    for sub in "${SUBDOMAIN_LIST[@]}"; do
        cleaned_sub=$(echo "${sub}" | xargs)
        echo "🌐 Subdomain: https://${cleaned_sub}.$DOMAIN"
    done
fi
