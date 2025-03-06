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

# Ask for the primary domain
ask "Enter your primary domain (e.g., example.com)" DOMAIN "example.com"

# Ask for subdomains (comma-separated)
ask "Enter subdomains (comma-separated, e.g., app, blog, api) or leave blank for none" SUBDOMAINS ""

# Install Nginx if not installed
if ! command -v nginx &> /dev/null; then
    echo "Nginx is not installed. Installing..."
    apt update && apt install -y nginx
fi

# Get public IP
SERVER_IP=$(curl -s ifconfig.me)
echo "Your server public IP is: $SERVER_IP"

# Display DNS setup instructions
echo "Please configure the following DNS records for your domain:"
echo "Type: A"
echo "Name: @ (or your subdomains: app, blog, etc.)"
echo "Value: $SERVER_IP"
echo "Wait for DNS propagation before proceeding."

# Function to configure a domain/subdomain in Nginx
configure_nginx() {
    local domain_name="$1"
    local webroot="/var/www/$domain_name"
    local config_file="/etc/nginx/sites-available/$domain_name"

    echo "Configuring Nginx for $domain_name..."

    # Create web root directory
    mkdir -p "$webroot"
    chown -R www-data:www-data "$webroot"
    chmod -R 755 "$webroot"

    # Create a simple index.html
    echo "<h1>Welcome to $domain_name</h1>" > "$webroot/index.html"

    # Create Nginx configuration file
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

    # Enable configuration
    ln -sf "$config_file" "/etc/nginx/sites-enabled/"

    echo "Nginx configuration for $domain_name created."
}

# Configure primary domain
configure_nginx "$DOMAIN"

# Configure subdomains
if [[ -n "$SUBDOMAINS" ]]; then
    IFS=',' read -ra SUBDOMAIN_LIST <<< "$SUBDOMAINS"
    for sub in "${SUBDOMAIN_LIST[@]}"; do
        subdomain="${sub// /}.$DOMAIN"  # Trim spaces and append domain
        configure_nginx "$subdomain"
    done
fi

# Test and reload Nginx
nginx -t && systemctl reload nginx
echo "Nginx is now configured for $DOMAIN and its subdomains."

# Ask for SSL setup
ask "Would you like to install an SSL certificate? (yes/no)" SSL_CHOICE "yes"
if [[ "$SSL_CHOICE" == "yes" ]]; then
    # Install Certbot if not installed
    if ! command -v certbot &> /dev/null; then
        echo "Installing Certbot..."
        apt update && apt install -y certbot python3-certbot-nginx
    fi

    # Generate SSL for primary domain and subdomains
    DOMAIN_LIST="-d $DOMAIN"
    if [[ -n "$SUBDOMAINS" ]]; then
        IFS=',' read -ra SUBDOMAIN_LIST <<< "$SUBDOMAINS"
        for sub in "${SUBDOMAIN_LIST[@]}"; do
            DOMAIN_LIST+=" -d ${sub// /}.$DOMAIN"
        done
    fi

    certbot --nginx $DOMAIN_LIST
    
    # Reload Nginx
    systemctl reload nginx
    echo "SSL setup complete. Your site is now accessible via HTTPS."

    # Enable auto-renewal
    certbot renew --dry-run
fi

echo "Setup complete!"
