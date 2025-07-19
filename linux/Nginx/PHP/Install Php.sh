#!/bin/bash

PHP_VERSION="8.3"

echo "🚀 Installing PHP ${PHP_VERSION} and FPM..."

# Update packages
sudo apt update
sudo apt install -y software-properties-common

# Add PHP PPA
sudo add-apt-repository -y ppa:ondrej/php
sudo apt update

# Install PHP core and FPM
echo "📦 Installing PHP and FPM..."
sudo apt install -y php${PHP_VERSION} php${PHP_VERSION}-fpm

# Enable and start FPM service
echo "🔧 Enabling and starting php${PHP_VERSION}-fpm..."
sudo systemctl enable php${PHP_VERSION}-fpm
sudo systemctl start php${PHP_VERSION}-fpm

# Check service status
echo "🧪 Checking php${PHP_VERSION}-fpm service..."
sudo systemctl status php${PHP_VERSION}-fpm --no-pager

# Check for socket
SOCK_FILE="/run/php/php${PHP_VERSION}-fpm.sock"
echo "📁 Checking for FPM socket at $SOCK_FILE..."
if [ -S "$SOCK_FILE" ]; then
  echo "✅ FPM socket is active: $SOCK_FILE"
else
  echo "❌ FPM socket not found at $SOCK_FILE"
  exit 1
fi

# Display PHP version
echo "🧪 PHP version: $(php -v | head -n 1)"

echo "🎉 PHP ${PHP_VERSION} with FPM and .sock is installed successfully."

exit 0
