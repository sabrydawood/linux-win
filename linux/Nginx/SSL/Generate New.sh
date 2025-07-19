#!/bin/bash

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "❌ This script must be run as root"
    exit 1
fi

# Prompt for domain
read -p "Enter the domain or subdomain (e.g., example.com or api.example.com): " DOMAIN
DOMAIN=$(echo "$DOMAIN" | xargs) # remove spaces

# Prompt for email
read -p "Enter your email for SSL notifications (e.g., you@example.com): " SSL_EMAIL
SSL_EMAIL=$(echo "$SSL_EMAIL" | xargs)

# Validate input
if [[ -z "$DOMAIN" || -z "$SSL_EMAIL" ]]; then
    echo "❌ Domain and email are required."
    exit 1
fi

# Install Certbot if not available
if ! command -v certbot &> /dev/null; then
    echo "🔧 Certbot not found. Installing..."
    apt update && apt install -y certbot python3-certbot-nginx
fi

# Request SSL Certificate
echo "🔐 Requesting SSL certificate for $DOMAIN..."
certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$SSL_EMAIL"

# Add auto-renew cron job
CRON_JOB="0 0 * * * certbot renew --quiet --post-hook \"systemctl reload nginx\""
(crontab -l 2>/dev/null | grep -qF "$CRON_JOB") || (
    echo "⏳ Adding auto-renewal cron job..."
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
)

echo "✅ SSL setup complete for $DOMAIN"
echo "🔄 Certificate will auto-renew daily at midnight."
