#!/bin/bash

echo "🔐 Setting up automatic SSL renewal with certbot..."

# Check for certbot and nginx
if ! command -v certbot &> /dev/null; then
    echo "❌ Certbot is not installed. Please install it first (e.g., sudo apt install certbot python3-certbot-nginx)"
    exit 1
fi

if ! command -v nginx &> /dev/null; then
    echo "❌ Nginx is not installed. Please install it first."
    exit 1
fi

# Define cron job line
CRON_JOB='0 3,15 * * * certbot renew --quiet --post-hook "systemctl reload nginx"'

# Check if the cron job already exists
if sudo crontab -l 2>/dev/null | grep -Fxq "$CRON_JOB"; then
    echo "✅ Cron job already exists."
else
    echo "➕ Adding certbot auto-renew cron job..."
    (sudo crontab -l 2>/dev/null; echo "$CRON_JOB") | sudo crontab -
    echo "✅ Cron job added successfully."
fi

# Perform dry-run to test renewal
echo "🧪 Running dry-run test for certificate renewal..."
if sudo certbot renew --dry-run; then
    echo "✅ Dry-run completed successfully."
else
    echo "❌ Dry-run failed. Please check certbot configuration."
    exit 1
fi

echo "🎉 Setup complete."
exit 0
