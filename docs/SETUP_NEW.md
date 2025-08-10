# Setup with New Q Business Resources

Use this guide if you need to create Q Business resources from scratch.

## Prerequisites

- AWS Account with Q Business permissions
- AWS CLI configured
- Node.js 18+

## Complete Setup

### 1. Deploy Infrastructure

Use the CloudFormation template to create all required resources:

```bash
aws cloudformation deploy \
  --template-file infrastructure/cloudformation.yaml \
  --stack-name qbusiness-public-sector \
  --parameter-overrides \
    QBusinessApplicationName="Government AI Assistant" \
    ThemeBucketName="your-unique-bucket-name-$(date +%s)" \
  --capabilities CAPABILITY_IAM
```

### 2. Upload Theme Assets

```bash
./scripts/upload-theme-assets.sh qbusiness-public-sector
```

### 3. Get Your Configuration

The CloudFormation stack outputs contain your IDs:

```bash
aws cloudformation describe-stacks \
  --stack-name qbusiness-public-sector \
  --query 'Stacks[0].Outputs'
```

### 4. Test Locally

```bash
npm install
npm start
```

Visit `http://localhost:3000` to verify the setup.

### 5. Deploy to Amplify

Follow the [Amplify Deployment Guide](AMPLIFY_SETUP.md) to deploy your application.

## What Gets Created

| Resource | Purpose |
|----------|---------|
| Q Business Application | AI application with anonymous access |
| Q Business Web Experience | Customized government interface |
| S3 Bucket | Theme assets storage |
| Secrets Manager Secret | Secure configuration storage |
| IAM Roles | Required permissions |

## Customization Options

The CloudFormation template supports these parameters:

- `QBusinessApplicationName` - Display name for your application
- `ThemeBucketName` - S3 bucket name (must be globally unique)
- `SessionDurationMinutes` - Session timeout (15-60 minutes)

## Next Steps

- [Deploy to AWS Amplify](AMPLIFY_SETUP.md)
- [Customize the Theme](CUSTOMIZATION.md)