# Setup with Existing Q Business Resources

Use this guide if you already have a Q Business Application ID and Web Experience ID.

## Prerequisites

- Amazon Q Business Application ID
- Amazon Q Business Web Experience ID  
- AWS CLI configured
- Node.js 18+

## Quick Setup

### 1. Configure Your IDs

Create or update `config/.env`:

```bash
SECRET_NAME=qbusiness-config
AWS_REGION=us-east-1
SESSION_DURATION_MINUTES=15
```

### 2. Store Configuration Securely

Run the setup script with your existing IDs:

```bash
./scripts/deploy-infrastructure.sh
```

When prompted, enter:
- Your Q Business Application ID
- Your Web Experience ID

This will:
- Create AWS Secrets Manager secret
- Set up S3 bucket for theme assets
- Upload government theme files
- Configure your web experience with government styling

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