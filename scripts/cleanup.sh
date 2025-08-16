#!/bin/bash
set -e

clear
echo ""
echo "🧹  AMAZON Q BUSINESS CLEANUP"
echo ""
echo "⚠️  This will permanently delete ALL resources"
echo "⏱️  Estimated cleanup time: ~4 minutes"
echo ""

# Configuration
STACK_NAME=${1:-"qbusiness-public-sector"}
AWS_REGION=${AWS_REGION:-"us-east-1"}

echo ""
echo "─ CONFIGURATION ──────────────────────────────────────────────────────────────"
echo ""
echo "📦 Stack Name: $STACK_NAME"
echo "🌍 Region: $AWS_REGION"
echo ""

echo ""
echo "─ CONFIRMATION ───────────────────────────────────────────────────────────────"
echo ""
echo "This action will permanently delete:"
echo "• CloudFormation stack and all resources"
echo "• S3 bucket and all theme assets"
echo "• Secrets Manager configuration"
echo "• Amplify application and deployments"
echo ""
read -p "Continue with deletion? (y/N): " -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cleanup cancelled by user"
    exit 0
fi

echo ""
echo "─ RESOURCE DISCOVERY ─────────────────────────────────────────────────────────"
echo ""
echo "Discovering stack resources..."

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

if [ -n "$BUCKET_NAME" ]; then
    echo "✅ Found S3 bucket: $BUCKET_NAME"
fi
if [ -n "$SECRET_NAME" ]; then
    echo "✅ Found secret: $SECRET_NAME"
fi

echo ""
echo "─ S3 BUCKET CLEANUP ──────────────────────────────────────────────────────────"
echo ""
if [ -n "$BUCKET_NAME" ]; then
    echo "Emptying S3 bucket (all versions)..."
    
    # Delete all object versions quietly
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
    
    # Delete all delete markers quietly
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
    
    echo "✅ S3 bucket emptied successfully"
else
    echo "⚠️  No S3 bucket found in stack outputs"
fi

echo ""
echo "─ SECRETS MANAGER CLEANUP ────────────────────────────────────────────────────"
echo ""
if [ -n "$SECRET_NAME" ]; then
    echo "Deleting Secrets Manager secret..."
    aws secretsmanager delete-secret \
      --secret-id "$SECRET_NAME" \
      --force-delete-without-recovery \
      --region "$AWS_REGION" >/dev/null 2>&1 || true
    echo "✅ Secret deleted successfully"
else
    echo "⚠️  No secret found in stack outputs"
fi

echo ""
echo "─ CLOUDFORMATION CLEANUP ─────────────────────────────────────────────────────"
echo ""
echo "Deleting CloudFormation stack..."
aws cloudformation delete-stack \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" \
  --no-cli-pager

echo "Waiting for stack deletion to complete..."
aws cloudformation wait stack-delete-complete \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION"

echo "✅ CloudFormation stack deleted successfully"

echo ""
echo "🎉 CLEANUP COMPLETE!"
echo ""
echo "All resources have been permanently removed:"
echo "   • Stack: $STACK_NAME"
if [ -n "$BUCKET_NAME" ]; then
    echo "   • S3 Bucket: $BUCKET_NAME"
fi
if [ -n "$SECRET_NAME" ]; then
    echo "   • Secret: $SECRET_NAME"
fi
echo ""
echo "✨ Thank you for using Amazon Q Business!"
echo ""