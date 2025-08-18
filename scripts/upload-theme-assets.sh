#!/bin/bash
set -e

clear
echo ""
echo "🎨  AMAZON Q BUSINESS THEME UPLOAD"
echo ""
echo "⏱️  Estimated upload time: ~1 minute"
echo ""

# Configuration
STACK_NAME=${1:-"qbusiness-public-sector"}
THEME_DIR=${2:-"public-sector"}
AWS_REGION=${AWS_REGION:-"us-east-1"}

echo ""
echo "─ CONFIGURATION ──────────────────────────────────────────────────────────────"
echo ""
echo "📦 Stack Name: $STACK_NAME"
echo "🎨 Theme: $THEME_DIR"
echo "🌍 Region: $AWS_REGION"
echo ""

echo ""
echo "─ VALIDATION ─────────────────────────────────────────────────────────────────"
echo ""

# Validate theme directory exists
if [[ ! -d "assets/themes/$THEME_DIR" ]]; then
  echo "❌ Theme directory 'assets/themes/$THEME_DIR' not found"
  echo ""
  echo "Available themes:"
  ls -1 assets/themes/ | sed 's/^/  • /'
  echo ""
  exit 1
fi

echo "✅ Theme directory validated: $THEME_DIR"
echo ""

echo ""
echo "─ INFRASTRUCTURE DISCOVERY ──────────────────────────────────────────────────"
echo ""

echo "🔍 Retrieving CloudFormation stack outputs..."

# Get bucket name and web experience endpoint from CloudFormation stack outputs
BUCKET_NAME=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" \
  --query 'Stacks[0].Outputs[?OutputKey==`ThemeBucketName`].OutputValue' \
  --output text)

WEB_EXPERIENCE_ENDPOINT=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" \
  --query 'Stacks[0].Outputs[?OutputKey==`QBusinessDefaultEndpoint`].OutputValue' \
  --output text)

AMPLIFY_DOMAIN=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" \
  --query 'Stacks[0].Outputs[?OutputKey==`AmplifyDefaultDomain`].OutputValue' \
  --output text)

# Get developer origins from CloudFormation parameters
DEVELOPER_ORIGINS=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" \
  --query 'Stacks[0].Parameters[?ParameterKey==`DeveloperOrigins`].ParameterValue' \
  --output text)

if [[ -z "$BUCKET_NAME" ]]; then
  echo "❌ Could not find ThemeBucketName in stack outputs"
  exit 1
fi

if [[ -z "$WEB_EXPERIENCE_ENDPOINT" ]]; then
  echo "❌ Could not find QBusinessDefaultEndpoint in stack outputs"
  exit 1
fi

if [[ -z "$AMPLIFY_DOMAIN" ]]; then
  echo "❌ Could not find AmplifyDefaultDomain in stack outputs"
  exit 1
fi

# Extract domains from endpoints (remove https:// and trailing /)
WEB_EXPERIENCE_DOMAIN=$(echo "$WEB_EXPERIENCE_ENDPOINT" | sed 's|https://||' | sed 's|/$||')
AMPLIFY_DOMAIN_CLEAN=$(echo "$AMPLIFY_DOMAIN" | sed 's|https://||' | sed 's|/$||')

# Clean developer origins (remove https:// and trailing /)
DEVELOPER_ORIGINS_CLEAN=""
if [[ -n "$DEVELOPER_ORIGINS" ]]; then
  IFS=',' read -ra ORIGINS_ARRAY <<< "$DEVELOPER_ORIGINS"
  for origin in "${ORIGINS_ARRAY[@]}"; do
    clean_origin=$(echo "$origin" | sed 's|https\?://||' | sed 's|/$||')
    if [[ -n "$DEVELOPER_ORIGINS_CLEAN" ]]; then
      DEVELOPER_ORIGINS_CLEAN="$DEVELOPER_ORIGINS_CLEAN,\"$clean_origin\""
    else
      DEVELOPER_ORIGINS_CLEAN="\"$clean_origin\""
    fi
  done
fi

echo "✅ Infrastructure discovered successfully"
echo ""

echo ""
echo "─ THEME UPLOAD ───────────────────────────────────────────────────────────────"
echo ""

echo "📤 Uploading theme assets to S3..."

# Upload theme assets quietly
cd "assets/themes/$THEME_DIR"
aws s3 sync . "s3://$BUCKET_NAME/" --no-cli-pager >/dev/null 2>&1

# Detect font file dynamically
FONT_FILE=$(find . -name "*.ttf" -o -name "*.woff" -o -name "*.woff2" -o -name "*.otf" | head -1 | sed 's|^\./||')
if [[ -z "$FONT_FILE" ]]; then
  echo "⚠️  No font files found in theme directory"
  FONT_URL=""
else
  FONT_URL="\"fontUrl\":\"https://$BUCKET_NAME.s3.$AWS_REGION.amazonaws.com/$FONT_FILE\","
fi

echo "✅ Theme assets uploaded successfully"
echo ""

echo ""
echo "─ S3 BUCKET POLICY UPDATE ───────────────────────────────────────────────────"
echo ""

echo "🔒 Updating S3 bucket policy..."

# Get list of all uploaded files for dynamic policy generation
UPLOADED_FILES=($(aws s3 ls "s3://$BUCKET_NAME/" --no-cli-pager | awk '{print $4}'))

# Generate resource ARNs for all uploaded files
RESOURCE_ARNS=""
for file in "${UPLOADED_FILES[@]}"; do
  if [[ -n "$RESOURCE_ARNS" ]]; then
    RESOURCE_ARNS="$RESOURCE_ARNS,"
  fi
  RESOURCE_ARNS="$RESOURCE_ARNS\"arn:aws:s3:::$BUCKET_NAME/$file\""
done

# Generate dynamic bucket policy with Referer condition
BUCKET_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyInsecureConnections",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::$BUCKET_NAME",
        "arn:aws:s3:::$BUCKET_NAME/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    },
    {
      "Sid": "PolicyForAmazonQWebAccessForWebExperienceArtifacts",
      "Effect": "Allow",
      "Principal": {
        "Service": "application.qbusiness.amazonaws.com"
      },
      "Action": "s3:GetObject",
      "Resource": [$RESOURCE_ARNS],
      "Condition": {
        "StringLike": {
          "aws:Referer": ["$WEB_EXPERIENCE_DOMAIN", "$AMPLIFY_DOMAIN_CLEAN"$(if [[ -n "$DEVELOPER_ORIGINS_CLEAN" ]]; then echo ", $DEVELOPER_ORIGINS_CLEAN"; fi)]
        },
        "Bool": {
          "aws:SecureTransport": "true"
        }
      }
    }
  ]
}
EOF
)

# Apply the dynamic bucket policy
echo "$BUCKET_POLICY" | aws s3api put-bucket-policy \
  --bucket "$BUCKET_NAME" \
  --policy file:///dev/stdin \
  --region "$AWS_REGION" \
  --no-cli-pager >/dev/null 2>&1

echo "✅ S3 bucket policy updated successfully"
echo ""

echo ""
echo "─ WEB EXPERIENCE UPDATE ─────────────────────────────────────────────────────"
echo ""

echo "🔄 Updating Q Business web experience configuration..."

# Get Q Business Application and Web Experience IDs
QBUSINESS_APP_ID=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" \
  --query 'Stacks[0].Outputs[?OutputKey==`QBusinessApplicationId`].OutputValue' \
  --output text)

QBUSINESS_WEB_EXP_ID=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" \
  --query 'Stacks[0].Outputs[?OutputKey==`QBusinessWebExperienceId`].OutputValue' \
  --output text | cut -d'|' -f2)

# Update Q Business web experience with theme customization and add Amplify domain to origins
CURRENT_ORIGINS=$(echo "$DEVELOPER_ORIGINS" | sed 's/,/","/g' | sed 's/^/"/' | sed 's/$/"/')
AMPLIFY_ORIGINS="\"$AMPLIFY_DOMAIN\",$CURRENT_ORIGINS"

aws qbusiness update-web-experience \
  --application-id "$QBUSINESS_APP_ID" \
  --web-experience-id "$QBUSINESS_WEB_EXP_ID" \
  --customization-configuration "{\"customCSSUrl\":\"https://$BUCKET_NAME.s3.$AWS_REGION.amazonaws.com/theme.css\",\"logoUrl\":\"https://$BUCKET_NAME.s3.$AWS_REGION.amazonaws.com/logo.png\",${FONT_URL}\"faviconUrl\":\"https://$BUCKET_NAME.s3.$AWS_REGION.amazonaws.com/favicon.ico\"}" \
  --origins "[$AMPLIFY_ORIGINS]" \
  --region "$AWS_REGION" \
  --no-cli-pager >/dev/null 2>&1

echo "✅ Web experience updated successfully"
echo ""

echo ""
echo "─ UPLOAD SUMMARY ────────────────────────────────────────────────────────────"
echo ""
echo "🎨 Theme: $THEME_DIR"
echo "📦 S3 Bucket: $BUCKET_NAME"
echo "🌐 Web Experience: $WEB_EXPERIENCE_ENDPOINT"
echo "🚀 Amplify Domain: $AMPLIFY_DOMAIN"
echo ""
echo "🎉 THEME UPLOAD COMPLETE!"
echo ""
echo "Your Q Business web experience has been updated with the new theme."
echo "Changes should be visible immediately when you refresh the application."
echo ""
