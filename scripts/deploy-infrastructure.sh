#!/bin/bash
set -e

echo "🏛️  Q Business Public Sector - Infrastructure Setup"
echo "=================================================="

# Configuration
SECRET_NAME="qbusiness-config"
BUCKET_NAME="amazon-q-business-ui-customizations"
AWS_REGION=${AWS_REGION:-"us-east-1"}

# Check prerequisites
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install and configure AWS CLI first."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "❌ jq not found. Please install jq first."
    exit 1
fi

# Get Q Business IDs from user
echo ""
echo "📋 Enter your Q Business configuration:"
read -p "Q Business Application ID: " QBUSINESS_APP_ID
read -p "Q Business Web Experience ID: " QBUSINESS_WEB_EXP_ID

if [[ -z "$QBUSINESS_APP_ID" || -z "$QBUSINESS_WEB_EXP_ID" ]]; then
    echo "❌ Both Application ID and Web Experience ID are required"
    exit 1
fi

echo ""
echo "🔐 Step 1: Creating Secrets Manager secret..."
aws secretsmanager create-secret \
  --name "$SECRET_NAME" \
  --description "Q Business Application and Web Experience IDs" \
  --secret-string "{
    \"QBUSINESS_APP_ID\": \"$QBUSINESS_APP_ID\",
    \"QBUSINESS_WEB_EXP_ID\": \"$QBUSINESS_WEB_EXP_ID\"
  }" \
  --region "$AWS_REGION" 2>/dev/null || \
aws secretsmanager update-secret \
  --secret-id "$SECRET_NAME" \
  --secret-string "{
    \"QBUSINESS_APP_ID\": \"$QBUSINESS_APP_ID\",
    \"QBUSINESS_WEB_EXP_ID\": \"$QBUSINESS_WEB_EXP_ID\"
  }" \
  --region "$AWS_REGION"

echo "✅ Secret created/updated: $SECRET_NAME"

echo ""
echo "📦 Step 2: Setting up S3 bucket for theme assets..."
if aws s3 ls "s3://$BUCKET_NAME" 2>/dev/null; then
    echo "✅ Bucket $BUCKET_NAME already exists"
else
    echo "🔨 Creating bucket $BUCKET_NAME"
    aws s3 mb "s3://$BUCKET_NAME" --region "$AWS_REGION"
fi

# Create and apply bucket policy
cat > temp-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "application.qbusiness.amazonaws.com"
      },
      "Action": ["s3:GetObject"],
      "Resource": [
        "arn:aws:s3:::$BUCKET_NAME/public-sector-theme.css",
        "arn:aws:s3:::$BUCKET_NAME/aws-logo.png",
        "arn:aws:s3:::$BUCKET_NAME/AmazonEmber_Bd.ttf",
        "arn:aws:s3:::$BUCKET_NAME/favicon.ico"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "true"
        }
      }
    }
  ]
}
EOF

aws s3api put-bucket-policy --bucket "$BUCKET_NAME" --policy file://temp-policy.json
aws s3api put-public-access-block --bucket "$BUCKET_NAME" --public-access-block-configuration BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false
rm temp-policy.json

echo "✅ S3 bucket configured with proper policies"

echo ""
echo "📤 Step 3: Uploading theme assets..."
aws s3 cp assets/ "s3://$BUCKET_NAME/" --recursive
echo "✅ Theme assets uploaded"

echo ""
echo "⚙️  Step 4: Configuring Q Business web experience..."
aws qbusiness update-web-experience \
--application-id "$QBUSINESS_APP_ID" \
--web-experience-id "$QBUSINESS_WEB_EXP_ID" \
--title "Demo Government AI Assistant" \
--subtitle "Providing secure information access for public sector agencies" \
--welcome-message "Welcome to your secure AI assistant. I can help you find information from approved government resources. How may I assist you today?" \
--sample-prompts-control-mode ENABLED \
--customization-configuration "{\"customCSSUrl\":\"https://$BUCKET_NAME.s3.$AWS_REGION.amazonaws.com/public-sector-theme.css\"}"

echo "✅ Q Business web experience configured"

echo ""
echo "🎉 Infrastructure setup complete!"
echo ""
echo "Next steps:"
echo "1. Follow the Amplify setup instructions in AMPLIFY-SETUP.md"
echo "2. Deploy your application to AWS Amplify"
echo "3. Add your Amplify domain to Q Business allowed URLs"