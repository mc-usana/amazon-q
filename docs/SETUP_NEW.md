# Setup with New Q Business Resources

Use this guide if you need to create Q Business resources from scratch.

## Prerequisites

- AWS Account with Q Business permissions
- AWS CLI configured
- Node.js 18+

## Complete Setup

### 1. Run Unified Deploy Script

```bash
./scripts/deploy.sh
```

When prompted:
1. Answer **"n"** when asked if you have existing Q Business resources
2. Enter application name (or press Enter for default)
3. Confirm deployment

This will:
- Deploy complete CloudFormation infrastructure
- Upload theme assets automatically
- Create local `.env` file for testing
- Display your configuration

### 2. Test Locally

```bash
npm install
npm start
```

Visit `http://localhost:3000` to verify the setup.

### 3. Deploy to Amplify

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