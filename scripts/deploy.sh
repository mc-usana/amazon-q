#!/bin/bash
set -e

echo "🏛️  Q Business Public Sector - Unified Deployment"
echo "================================================"

# Configuration
STACK_NAME=${1:-"qbusiness-public-sector"}
AWS_REGION=${AWS_REGION:-"us-east-1"}
GITHUB_BRANCH=${2:-"main"}
GITHUB_REPO=${3:-""}
GITHUB_TOKEN=${4:-""}

echo ""
echo "Do you have existing Q Business resources? (y/n)"
read -r HAS_EXISTING

if [[ "$HAS_EXISTING" =~ ^[Yy]$ ]]; then
    echo ""
    echo "📋 Enter your existing Q Business details:"
    read -p "Q Business Application ID: " EXISTING_APP_ID
    read -p "Q Business Web Experience ID: " EXISTING_WEB_EXP_ID
    
    if [[ -z "$EXISTING_APP_ID" || -z "$EXISTING_WEB_EXP_ID" ]]; then
        echo "❌ Both Application ID and Web Experience ID are required"
        exit 1
    fi
    
    echo ""
    echo "🔐 Creating Secrets Manager secret with your existing IDs..."
    aws secretsmanager create-secret \
      --name "qbusiness-config" \
      --description "Q Business Application and Web Experience IDs" \
      --secret-string "{
        \"QBUSINESS_APP_ID\": \"$EXISTING_APP_ID\",
        \"QBUSINESS_WEB_EXP_ID\": \"$EXISTING_WEB_EXP_ID\"
      }" \
      --region "$AWS_REGION" 2>/dev/null || \
    aws secretsmanager update-secret \
      --secret-id "qbusiness-config" \
      --secret-string "{
        \"QBUSINESS_APP_ID\": \"$EXISTING_APP_ID\",
        \"QBUSINESS_WEB_EXP_ID\": \"$EXISTING_WEB_EXP_ID\"
      }" \
      --region "$AWS_REGION"
    
    echo "✅ Secret configured with existing resources"
    
else
    echo ""
    echo "🚀 Creating complete Q Business infrastructure from scratch..."
    
    # Get application name with validation
    while true; do
        read -p "Application name (alphanumeric, hyphens, underscores only) [GovernmentAIAssistant]: " APP_NAME
        APP_NAME=${APP_NAME:-"GovernmentAIAssistant"}
        
        if [[ $APP_NAME =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ ]]; then
            break
        else
            echo "❌ Invalid name. Must start with alphanumeric and contain only letters, numbers, hyphens, and underscores."
        fi
    done
    
    # Generate unique bucket name
    BUCKET_NAME="qbusiness-theme-$(date +%s)"
    
    echo "Stack Name: $STACK_NAME"
    echo "Application Name: $APP_NAME"
    echo "Theme Bucket: $BUCKET_NAME"
    echo "AWS Region: $AWS_REGION"
    echo ""
    
    read -p "Press Enter to continue or Ctrl+C to cancel..."
    
    PARAMS="QBusinessApplicationName=$APP_NAME ThemeBucketName=$BUCKET_NAME GitHubBranch=$GITHUB_BRANCH"
    
    if [[ -n "$GITHUB_REPO" && -n "$GITHUB_TOKEN" ]]; then
        PARAMS="$PARAMS GitHubRepository=$GITHUB_REPO GitHubAccessToken=$GITHUB_TOKEN"
    fi
    
    aws cloudformation deploy \
      --template-file infrastructure/cloudformation.yaml \
      --stack-name "$STACK_NAME" \
      --parameter-overrides $PARAMS \
      --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
      --region "$AWS_REGION"
    
    echo "✅ Infrastructure deployed successfully!"
fi

echo ""
echo "📤 Uploading theme assets..."
./scripts/upload-theme-assets.sh "$STACK_NAME"

echo ""
echo "📋 Your configuration:"
if [[ "$HAS_EXISTING" =~ ^[Yy]$ ]]; then
    echo "Application ID: $EXISTING_APP_ID"
    echo "Web Experience ID: $EXISTING_WEB_EXP_ID"
else
    aws cloudformation describe-stacks \
      --stack-name "$STACK_NAME" \
      --query 'Stacks[0].Outputs[?OutputKey==`QBusinessApplicationId` || OutputKey==`QBusinessWebExperienceId` || OutputKey==`AmplifyComputeRoleArn` || OutputKey==`AmplifyDefaultDomain`].[OutputKey,OutputValue]' \
      --output table \
      --region "$AWS_REGION"
fi

echo ""
# Create local .env file with actual secret name
echo "📝 Creating local .env file..."
SECRET_ARN=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" \
  --query 'Stacks[0].Outputs[?OutputKey==`SecretsManagerSecretName`].OutputValue' \
  --output text)

# Extract just the secret name from the ARN (remove the random suffix AWS adds)
SECRET_NAME_ACTUAL=$(echo "$SECRET_ARN" | sed 's/.*secret:\([^-]*-[^-]*-[^-]*-[^-]*\).*/\1/')

cat > config/.env << EOL
SECRET_NAME=$SECRET_NAME_ACTUAL
AWS_REGION=$AWS_REGION
SESSION_DURATION_MINUTES=15
EOL

# Update amplify.yml with actual secret name
sed -i.bak "s/SECRET_NAME: .*/SECRET_NAME: $SECRET_NAME_ACTUAL/" amplify.yml
rm -f amplify.yml.bak

echo "✅ Local .env and amplify.yml updated with actual secret name"

echo ""
echo "📤 Committing and pushing changes to trigger Amplify build..."
git add amplify.yml config/.env
git commit -m "Update amplify.yml and .env with deployed infrastructure config"
git push origin "$GITHUB_BRANCH"

echo "🎉 Deployment complete!"
echo ""
echo "Next steps:"
echo "1. Test locally: npm install && npm start"
echo "2. Deploy to Amplify: Follow docs/AMPLIFY_SETUP.md"
echo "3. Add your Amplify domain to Q Business allowed URLs"