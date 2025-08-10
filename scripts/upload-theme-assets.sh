#!/bin/bash
set -e

# Upload theme assets to S3 bucket created by CloudFormation
STACK_NAME=${1:-"qbusiness-public-sector"}

echo "🎨 Uploading theme assets to S3..."

# Get bucket name from CloudFormation stack outputs
BUCKET_NAME=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --query 'Stacks[0].Outputs[?OutputKey==`ThemeBucketName`].OutputValue' \
  --output text)

if [[ -z "$BUCKET_NAME" ]]; then
  echo "❌ Could not find ThemeBucketName in stack outputs"
  echo "Make sure the CloudFormation stack '$STACK_NAME' exists and has completed successfully"
  exit 1
fi

echo "📦 Uploading to bucket: $BUCKET_NAME"

# Upload theme assets
cd assets
aws s3 cp public-sector-theme.css "s3://$BUCKET_NAME/"
aws s3 cp aws-logo.png "s3://$BUCKET_NAME/"
aws s3 cp AmazonEmber_Bd.ttf "s3://$BUCKET_NAME/"
aws s3 cp favicon.ico "s3://$BUCKET_NAME/"

echo "✅ Theme assets uploaded successfully"
echo ""
echo "Next steps:"
echo "1. Follow AMPLIFY-SETUP.md to deploy your web application"
echo "2. Your Q Business configuration is stored in AWS Secrets Manager as 'qbusiness-config'"