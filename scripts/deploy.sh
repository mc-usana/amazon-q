#!/bin/bash
set -e

clear
echo ""
echo "🏛️  AMAZON Q BUSINESS DEPLOYMENT"
echo ""
echo "⏱️  Estimated deployment time: ~4 minutes"
echo ""

# Configuration
STACK_NAME=${1:-"qbusiness-public-sector"}
GITHUB_BRANCH=${2:-"main"}
GITHUB_REPO=${3:-""}
GITHUB_TOKEN=${4:-""}
AWS_REGION=${AWS_REGION:-"us-east-1"}

echo ""
echo "─ CONFIGURATION ──────────────────────────────────────────────────────────────"
echo ""
echo "📦 Stack Name: $STACK_NAME"
echo "🌿 Branch: $GITHUB_BRANCH"
echo "🌍 Region: $AWS_REGION"
echo ""

echo ""
echo "─ APPLICATION SETUP ──────────────────────────────────────────────────────────"
echo ""
# Get application name with validation
while true; do
    echo -n "Application name [GovernmentAIAssistant]: "
    read APP_NAME
    APP_NAME=${APP_NAME:-"GovernmentAIAssistant"}
    
    if [[ $APP_NAME =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ ]]; then
        echo "✅ Application name validated: $APP_NAME"
        break
    else
        echo "❌ Invalid name. Use alphanumeric, hyphens, and underscores only."
    fi
done
echo ""

echo ""
echo "─ INFRASTRUCTURE DEPLOYMENT ──────────────────────────────────────────────────"
echo ""
echo "🚀 Deploying CloudFormation stack..."
echo ""

PARAMS="QBusinessApplicationName=$APP_NAME GitHubBranch=$GITHUB_BRANCH"

if [[ -n "$GITHUB_REPO" && -n "$GITHUB_TOKEN" ]]; then
    PARAMS="$PARAMS GitHubRepository=$GITHUB_REPO GitHubAccessToken=$GITHUB_TOKEN"
fi

aws cloudformation deploy \
  --template-file infrastructure/cloudformation.yaml \
  --stack-name "$STACK_NAME" \
  --parameter-overrides $PARAMS \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --region "$AWS_REGION" \
  --no-cli-pager

echo "✅ Infrastructure deployed successfully!"
echo ""

echo ""
echo "─ THEME ASSETS ───────────────────────────────────────────────────────────────"
echo ""
echo "Uploading custom theme assets..."
./scripts/upload-theme-assets.sh "$STACK_NAME"
echo "✅ Theme assets uploaded successfully"
echo ""

echo ""
echo "─ AMPLIFY DEPLOYMENT ─────────────────────────────────────────────────────────"
echo ""
if [[ -n "$GITHUB_REPO" && -n "$GITHUB_TOKEN" ]]; then
    echo "Committing changes to trigger Amplify build..."
    git add -A
    git commit -m "Update infrastructure configuration" || echo "No changes to commit"
    git push origin "$GITHUB_BRANCH"
    echo "✅ Changes pushed to trigger Amplify deployment"
else
    echo "⚠️  No GitHub integration - Amplify deployment requires manual setup"
fi
echo ""

echo ""
echo "─ DEPLOYMENT SUMMARY ─────────────────────────────────────────────────────────"
echo ""
aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --query 'Stacks[0].Outputs[?OutputKey==`QBusinessApplicationId` || OutputKey==`QBusinessWebExperienceId` || OutputKey==`AmplifyComputeRoleArn` || OutputKey==`AmplifyDefaultDomain` || OutputKey==`SecretsManagerSecretName`].[OutputKey,OutputValue]' \
  --output table \
  --region "$AWS_REGION" \
  --no-cli-pager
echo ""

echo "🎉 DEPLOYMENT COMPLETE!"
echo ""

if [[ -n "$GITHUB_REPO" && -n "$GITHUB_TOKEN" ]]; then
    echo "NEXT STEPS:"
    echo "   1. Visit your AmplifyDefaultDomain to verify deployment"
    echo "   2. Test locally: npm install && npm start"
else
    echo "NEXT STEPS:"
    echo "   1. Test locally: npm install && npm start"
fi

echo ""
echo "✨ Thank you for using Amazon Q Business!"
echo ""