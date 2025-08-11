# Setup with Existing Q Business Resources

Use this guide if you already have a Q Business Application ID and Web Experience ID.

## Prerequisites

- Amazon Q Business Application ID
- Amazon Q Business Web Experience ID  
- AWS CLI configured
- Node.js 18+

## Quick Setup

### 1. Run Unified Deploy Script

```bash
./scripts/deploy.sh
```

When prompted:
1. Answer **"y"** when asked if you have existing Q Business resources
2. Enter your Q Business Application ID
3. Enter your Web Experience ID

This will:
- Create AWS Secrets Manager secret with dynamic name
- Set up S3 bucket for theme assets
- Upload government theme files
- Configure your web experience with government styling
- Create local `.env` file for testing

### 3. Test Locally

```bash
npm install
npm start
```

Visit `http://localhost:3000` to verify the setup.

### 4. Deploy to Amplify

Follow the [Amplify Deployment Guide](AMPLIFY_SETUP.md) to deploy your application.

## What Gets Configured

- **Theme Assets**: Government color scheme, logo, fonts
- **Sample Prompts**: Government-appropriate examples
- **Session Management**: Configurable timeout
- **Security**: Credentials stored in AWS Secrets Manager

## Next Steps

- [Deploy to AWS Amplify](AMPLIFY_SETUP.md)
- [Customize the Theme](CUSTOMIZATION.md)