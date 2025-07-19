#!/bin/bash

# Define Node.js version and installation details
NODE_VERSION="v20.10.0"
NODE_DIST="node-${NODE_VERSION}-linux-x64"
NODE_TAR="${NODE_DIST}.tar.xz"
NODE_URL="https://nodejs.org/dist/${NODE_VERSION}/${NODE_TAR}"
INSTALL_DIR="/opt/nodejs"

echo "🚀 Starting Node.js ${NODE_VERSION} installation..."

# Download Node.js tarball
echo "📥 Downloading ${NODE_TAR}..."
sudo curl -O "$NODE_URL"
if [ $? -ne 0 ]; then
  echo "❌ Failed to download Node.js. Please check your internet connection or URL."
  exit 1
fi

echo "✅ Downloaded ${NODE_TAR} successfully."

# Create installation directory if it doesn't exist
echo "📁 Creating installation directory at ${INSTALL_DIR}..."
sudo mkdir -p "$INSTALL_DIR"

# Extract Node.js to the installation directory
echo "📦 Extracting Node.js archive..."
sudo tar xvfJ "$NODE_TAR" -C "$INSTALL_DIR"
if [ $? -ne 0 ]; then
  echo "❌ Failed to extract Node.js archive."
  exit 1
fi

# Update PATH for current session
echo "🔧 Updating PATH for current session..."
export PATH="${INSTALL_DIR}/${NODE_DIST}/bin:$PATH"

# Verify installation
echo "🧪 Verifying Node.js installation..."
node -v
if [ $? -ne 0 ]; then
  echo "❌ Node.js is not installed correctly or PATH is not updated."
  exit 1
fi

echo "🎉 Node.js ${NODE_VERSION} installed successfully."

exit 0
