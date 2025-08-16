#!/bin/bash
set -e

# Upload theme assets to S3 bucket created by CloudFormation
STACK_NAME=${1:-"qbusiness-public-sector"}

# Get bucket name from CloudFormation stack outputs
BUCKET_NAME=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "${AWS_REGION:-us-east-1}" \
  --query 'Stacks[0].Outputs[?OutputKey==`ThemeBucketName`].OutputValue' \
  --output text)

if [[ -z "$BUCKET_NAME" ]]; then
  echo "❌ Could not find ThemeBucketName in stack outputs"
  echo "Make sure the CloudFormation stack '$STACK_NAME' exists and has completed successfully"
  exit 1
fi

# Upload theme assets quietly
cd assets
aws s3 cp public-sector-theme.css "s3://$BUCKET_NAME/" --no-cli-pager >/dev/null 2>&1
aws s3 cp aws-logo.png "s3://$BUCKET_NAME/" --no-cli-pager >/dev/null 2>&1
aws s3 cp AmazonEmber_Bd.ttf "s3://$BUCKET_NAME/" --no-cli-pager >/dev/null 2>&1
aws s3 cp favicon.ico "s3://$BUCKET_NAME/" --no-cli-pager >/dev/null 2>&1

