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
echo "─ LOCAL DEVELOPMENT SETUP ────────────────────────────────────────────────────"
echo ""
echo "Creating local .env file for development..."
QBUSINESS_CONFIG_ID=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" \
  --query 'Stacks[0].Outputs[?OutputKey==`SecretsManagerSecretName`].OutputValue' \
  --output text)

cat > config/.env << EOF
QBUSINESS_CONFIG_ID=$QBUSINESS_CONFIG_ID
REGION=$AWS_REGION
SESSION_DURATION_MINUTES=15
EOF

echo "✅ Local .env created for development"
echo ""

echo ""
echo "─ AMPLIFY DEPLOYMENT ─────────────────────────────────────────────────────────"
echo ""
if [[ -n "$GITHUB_REPO" && -n "$GITHUB_TOKEN" ]]; then
    echo "Committing changes to trigger Amplify build..."
    git add -A
    git commit --allow-empty -m "Update infrastructure configuration"
    git push origin "$GITHUB_BRANCH"
    echo "✅ Changes pushed to trigger Amplify deployment"
    
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
                echo "Build status: $LATEST_JOB - in progress..."
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
else
    echo "⚠️  No GitHub integration - Amplify deployment requires manual setup"
fi
echo ""

echo ""
echo "─ DEPLOYMENT SUMMARY ─────────────────────────────────────────────────────────"
echo ""
aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --query 'Stacks[0].Outputs[?OutputKey==`QBusinessApplicationId` || OutputKey==`QBusinessWebExperienceId` || OutputKey==`AmplifyComputeRoleArn` || OutputKey==`AmplifyDefaultDomain` || OutputKey==`QBusinessDefaultEndpoint` || OutputKey==`SecretsManagerSecretName`].[OutputKey,OutputValue]' \
  --output table \
  --region "$AWS_REGION" \
  --no-cli-pager
echo ""

echo "🎉 DEPLOYMENT COMPLETE!"
echo ""

if [[ -n "$GITHUB_REPO" && -n "$GITHUB_TOKEN" ]]; then
    echo "NEXT STEPS:"
    echo "   1. Visit your AmplifyDefaultDomain to verify deployment"
    echo "   2. Visit your QBusinessDefaultEndpoint to access the Q Business chat"
    echo "   3. Test locally: npm install && npm start"
else
    echo "NEXT STEPS:"
    echo "   1. Test locally: npm install && npm start"
fi

echo ""
echo "✨ Thank you for using Amazon Q Business!"
echo ""