#!/bin/bash
# Complete setup script for Q Business public sector deployment

# Load environment variables
set -a
source .env
set +a

echo "🏛️  Setting up Q Business Public Sector Application"

# 0. Create Secrets Manager secret
echo "🔐 Creating Secrets Manager secret..."
./create-secret.sh

# 1. Setup S3 bucket for theme assets
echo "📦 Setting up S3 bucket..."
BUCKET_NAME="amazon-q-business-ui-customizations"
AWS_REGION=${AWS_REGION:-"us-east-1"}

if ! aws s3 ls "s3://$BUCKET_NAME" --no-verify-ssl 2>&1 | grep -q 'NoSuchBucket'; then
  echo "✅ Bucket $BUCKET_NAME already exists"
else
  echo "🔨 Creating bucket $BUCKET_NAME"
  aws s3 mb s3://$BUCKET_NAME --region $AWS_REGION --no-verify-ssl
fi

# Apply bucket policy
sed "s/amazon-q-business-ui-customizations/$BUCKET_NAME/g" s3-bucket-policy.json > temp-policy.json
aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://temp-policy.json --no-verify-ssl
rm temp-policy.json

aws s3api put-public-access-block --bucket $BUCKET_NAME --public-access-block-configuration BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false --no-verify-ssl

# 2. Upload all assets to S3
echo "📤 Uploading theme assets..."
aws s3 cp assets/public-sector-theme.css s3://$BUCKET_NAME/public-sector-theme.css --no-verify-ssl
aws s3 cp assets/ s3://$BUCKET_NAME/ --recursive --exclude "*.css" --no-verify-ssl

# 3. Get Q Business IDs from Secrets Manager
echo "🔍 Retrieving Q Business configuration from Secrets Manager..."
SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id qbusiness-config --query SecretString --output text --no-verify-ssl)
QBUSINESS_APP_ID=$(echo $SECRET_JSON | jq -r '.QBUSINESS_APP_ID')
QBUSINESS_WEB_EXP_ID=$(echo $SECRET_JSON | jq -r '.QBUSINESS_WEB_EXP_ID')

# 4. Configure web experience settings
echo "⚙️  Configuring web experience..."
aws qbusiness update-web-experience \
--application-id $QBUSINESS_APP_ID \
--web-experience-id $QBUSINESS_WEB_EXP_ID \
--title "Demo Government AI Assistant" \
--subtitle "Providing secure information access for public sector agencies" \
--welcome-message "Welcome to your secure AI assistant. I can help you find information from approved government resources. How may I assist you today?" \
--sample-prompts-control-mode ENABLED \
--customization-configuration "{\"customCSSUrl\":\"https://$BUCKET_NAME.s3.$AWS_REGION.amazonaws.com/public-sector-theme.css\"}" \
--no-verify-ssl

echo "✅ Setup complete! Your Q Business public sector application is ready."