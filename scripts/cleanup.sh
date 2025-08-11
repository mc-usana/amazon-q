#!/bin/bash
set -e

echo "🧹 Q Business Public Sector - Cleanup Script"
echo "============================================="

# Configuration
STACK_NAME=${1:-"qbusiness-public-sector"}
AWS_REGION=${AWS_REGION:-"us-east-1"}

echo "Stack Name: $STACK_NAME"
echo "AWS Region: $AWS_REGION"
echo ""

read -p "⚠️  This will delete ALL resources. Continue? (y/N): " -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "🗑️  Step 1: Getting stack resources..."

# Get S3 bucket name and secret name from stack outputs
BUCKET_NAME=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" \
  --query 'Stacks[0].Outputs[?OutputKey==`ThemeBucketName`].OutputValue' \
  --output text 2>/dev/null || echo "")

SECRET_NAME=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" \
  --query 'Stacks[0].Outputs[?OutputKey==`SecretsManagerSecretName`].OutputValue' \
  --output text 2>/dev/null || echo "")

echo "📦 Step 2: Emptying S3 bucket..."
if [ -n "$BUCKET_NAME" ]; then
    echo "Emptying bucket: $BUCKET_NAME"
    
    # Delete all object versions
    aws s3api list-object-versions \
      --bucket "$BUCKET_NAME" \
      --region "$AWS_REGION" \
      --query 'Versions[].{Key:Key,VersionId:VersionId}' \
      --output text 2>/dev/null | while read -r key version_id; do
        if [ -n "$key" ] && [ "$key" != "None" ]; then
            aws s3api delete-object \
              --bucket "$BUCKET_NAME" \
              --key "$key" \
              --version-id "$version_id" \
              --region "$AWS_REGION" >/dev/null 2>&1 || true
        fi
    done
    
    # Delete all delete markers
    aws s3api list-object-versions \
      --bucket "$BUCKET_NAME" \
      --region "$AWS_REGION" \
      --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' \
      --output text 2>/dev/null | while read -r key version_id; do
        if [ -n "$key" ] && [ "$key" != "None" ]; then
            aws s3api delete-object \
              --bucket "$BUCKET_NAME" \
              --key "$key" \
              --version-id "$version_id" \
              --region "$AWS_REGION" >/dev/null 2>&1 || true
        fi
    done
    
    echo "✅ S3 bucket emptied (all versions)"
else
    echo "No S3 bucket found in stack outputs"
fi

echo ""
echo "🔐 Step 3: Deleting Secrets Manager secret..."
if [ -n "$SECRET_NAME" ]; then
    echo "Deleting secret: $SECRET_NAME"
    aws secretsmanager delete-secret \
      --secret-id "$SECRET_NAME" \
      --force-delete-without-recovery \
      --region "$AWS_REGION" 2>/dev/null || echo "Secret already deleted or doesn't exist"
    echo "✅ Secret deleted"
else
    echo "No secret found in stack outputs"
fi

echo ""
echo "☁️  Step 4: Deleting CloudFormation stack..."
aws cloudformation delete-stack \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION"

echo "⏳ Waiting for stack deletion to complete..."
aws cloudformation wait stack-delete-complete \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION"

echo "✅ CloudFormation stack deleted"

echo ""
echo "🎉 Cleanup completed successfully!"
echo ""
echo "All Q Business resources have been removed:"
echo "- CloudFormation stack: $STACK_NAME"
echo "- S3 bucket: $BUCKET_NAME"
echo "- Secrets Manager secret: $SECRET_NAME"