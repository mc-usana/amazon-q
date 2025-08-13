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
echo "📝 Creating local .env file for development..."
SECRET_NAME=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" \
  --query 'Stacks[0].Outputs[?OutputKey==`SecretsManagerSecretName`].OutputValue' \
  --output text)

cat > config/.env << EOF
SECRET_NAME=$SECRET_NAME
REGION=$AWS_REGION
SESSION_DURATION_MINUTES=15
EOF

echo "✅ Local .env created for development"

echo ""
echo "📤 Committing and pushing changes to trigger Amplify build..."
git add -A
git commit -m "Update infrastructure configuration"
git push origin "$GITHUB_BRANCH"

if [[ -n "$GITHUB_REPO" && -n "$GITHUB_TOKEN" ]]; then
    echo ""
    echo "⏳ Monitoring Amplify build progress..."
    
    # Get Amplify App ID from stack outputs
    AMPLIFY_APP_ID=$(aws cloudformation describe-stacks \
      --stack-name "$STACK_NAME" \
      --region "$AWS_REGION" \
      --query 'Stacks[0].Outputs[?OutputKey==`AmplifyAppId`].OutputValue' \
      --output text)
    
    # Monitor build status
    while true; do
        LATEST_JOB=$(aws amplify list-jobs \
          --app-id "$AMPLIFY_APP_ID" \
          --branch-name "$GITHUB_BRANCH" \
          --region "$AWS_REGION" \
          --query 'jobSummaries[0].status' \
          --output text)
        
        case "$LATEST_JOB" in
            "RUNNING"|"PENDING")
                echo "Build status: $LATEST_JOB - in progress ..."
                sleep 30
                ;;
            "SUCCEED")
                echo "✅ Amplify build completed successfully!"
                
                # Update Q Business web experience with Amplify domain
                echo "🔗 Adding Amplify domain to Q Business allowed origins..."
                
                AMPLIFY_DOMAIN=$(aws cloudformation describe-stacks \
                  --stack-name "$STACK_NAME" \
                  --region "$AWS_REGION" \
                  --query 'Stacks[0].Outputs[?OutputKey==`AmplifyDefaultDomain`].OutputValue' \
                  --output text)
                
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
                
                aws qbusiness update-web-experience \
                  --application-id "$QBUSINESS_APP_ID" \
                  --web-experience-id "$QBUSINESS_WEB_EXP_ID" \
                  --origins "$AMPLIFY_DOMAIN" "http://localhost:3000" \
                  --region "$AWS_REGION"
                
                echo "✅ Q Business web experience updated with Amplify domain"
                break
                ;;
            "FAILED"|"CANCELLED")
                echo "❌ Amplify build failed with status: $LATEST_JOB"
                exit 1
                ;;
            *)
                echo "Unknown build status: $LATEST_JOB"
                break
                ;;
        esac
    done
fi

echo "🎉 Deployment complete!"
echo ""
echo "Next steps:"
echo "1. Test locally: npm install && npm start"
echo "2. Deploy to Amplify: Follow docs/AMPLIFY_SETUP.md"
echo "3. Add your Amplify domain to Q Business allowed URLs"