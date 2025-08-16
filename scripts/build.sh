#!/bin/bash

# Load environment variables from config/.env file
if [ -f config/.env ]; then
  set -a
  source config/.env
  set +a
fi

# Create necessary directories
mkdir -p ./.amplify-hosting/compute/default

# Copy source files
cp ./src/index.js ./.amplify-hosting/compute/default/
cp ./src/utils.js ./.amplify-hosting/compute/default/
cp ./src/secrets.js ./.amplify-hosting/compute/default/
cp ./src/styles.css ./.amplify-hosting/compute/default/

# Copy node_modules for deployment
cp -r ./node_modules ./.amplify-hosting/compute/default/node_modules

# Copy deploy-manifest.json to the .amplify-hosting directory
cp ./config/deploy-manifest.json ./.amplify-hosting/

# Ensure package.json exists in compute/default with type: module
cat > ./.amplify-hosting/compute/default/package.json << EOL
{
  "name": "express-amplify-app-compute",
  "version": "1.0.0",
  "type": "module",
  "main": "index.js"
}
EOL

# Create environment file using Amplify build-time environment variables
cat > ./.amplify-hosting/compute/default/.env << EOL
QBUSINESS_CONFIG_ID=${QBUSINESS_CONFIG_ID:-qbusiness-config}
REGION=${REGION:-us-east-1}
SESSION_DURATION_MINUTES=${SESSION_DURATION_MINUTES:-15}
EOL

echo "Environment variables written to .env:"
cat ./.amplify-hosting/compute/default/.env

echo "Build completed successfully"