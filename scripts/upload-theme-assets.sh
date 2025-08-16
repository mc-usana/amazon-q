#!/bin/bash
set -e

# Upload theme assets to S3 bucket created by CloudFormation
STACK_NAME=${1:-"qbusiness-public-sector"}
AWS_REGION=${AWS_REGION:-"us-east-1"}

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

# Upload theme assets quietly
cd assets
aws s3 cp public-sector-theme.css "s3://$BUCKET_NAME/" --no-cli-pager >/dev/null 2>&1
aws s3 cp aws-logo.png "s3://$BUCKET_NAME/" --no-cli-pager >/dev/null 2>&1
aws s3 cp AmazonEmber_Bd.ttf "s3://$BUCKET_NAME/" --no-cli-pager >/dev/null 2>&1
aws s3 cp favicon.ico "s3://$BUCKET_NAME/" --no-cli-pager >/dev/null 2>&1

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
          "aws:Referer": ["$WEB_EXPERIENCE_DOMAIN", "$AMPLIFY_DOMAIN_CLEAN", "localhost:3000"]
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

echo "✅ Theme assets uploaded and bucket policy updated with Referer condition"

