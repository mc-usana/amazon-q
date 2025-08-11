# Setup Guide

## Quick Start

### 1. Deploy Infrastructure

```bash
git clone <repository-url>
cd qbamplify
npm install
./scripts/deploy.sh
```

The script will ask if you have existing Q Business resources:
- **New setup**: Answer "n" to create everything from scratch
- **Existing resources**: Answer "y" and provide your application ID

### 2. Configure Q Business URLs

Add these URLs to your Q Business web experience allowed websites:
- Local testing: `http://localhost:3000`
- Production: Your Amplify domain (after deployment)

Go to: Q Business Console → Your Application → Web Experience → Allowed websites

### 3. Test Locally

```bash
npm start
```

Visit `http://localhost:3000`

### 4. Deploy to Amplify

1. Connect your GitHub repository to AWS Amplify
2. Use build settings: `amplify.yml` (already configured)
3. Add environment variable: `AMPLIFY_MONOREPO_APP_ROOT` = `/`
4. Deploy and get your production URL
5. Add production URL to Q Business allowed websites

## What Gets Created

- Q Business Application with anonymous access
- S3 bucket for theme assets
- Secrets Manager for secure configuration
- IAM roles with required permissions

## Troubleshooting

- **500 errors**: Check AWS credentials and permissions
- **Iframe not loading**: Verify URLs are added to Q Business allowed websites
- **Build failures**: Ensure Node.js 18+ and all dependencies installed

## Next Steps

- [Customize theme and branding](CUSTOMIZATION.md)
- Upload documents to your Q Business application
- Configure session duration (15-60 minutes, default: 60)