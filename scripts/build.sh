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

# Get secret name dynamically from CloudFormation stack
SECRET_NAME_FROM_STACK=$(aws cloudformation describe-stacks --stack-name qbusiness-public-sector --region us-east-1 --query 'Stacks[0].Outputs[?OutputKey==`SecretsManagerSecretName`].OutputValue' --output text 2>/dev/null || echo "")

# Create environment file using dynamic values
cat > ./.amplify-hosting/compute/default/.env << EOL
SECRET_NAME=${SECRET_NAME_FROM_STACK:-${SECRET_NAME:-qbusiness-config}}
AWS_REGION=${AWS_REGION:-us-east-1}
SESSION_DURATION_MINUTES=${SESSION_DURATION_MINUTES:-15}
EOL

# Optional: Run complete Q Business setup during Amplify build
if [ "$CUSTOMIZE_WEB_EXPERIENCE" = "true" ]; then
  echo "Running Q Business public sector setup..."
  ./scripts/setup.sh || echo "Q Business setup failed (optional)"
fi

echo "Build completed successfully"