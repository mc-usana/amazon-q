# Infrastructure Setup Guide

## Overview

This solution requires AWS infrastructure to be set up before deploying the Amplify application. You have two options:

## Option 1: CloudFormation Template (Recommended)

The `infrastructure/cloudformation.yaml` template creates all required resources:

- Q Business Application with anonymous access
- Q Business Index and Retriever
- Q Business Web Experience with government theming
- S3 bucket for theme assets with proper policies
- Secrets Manager secret for configuration
- IAM roles and policies

### Deploy Infrastructure

```bash
aws cloudformation deploy \
  --template-file infrastructure/cloudformation.yaml \
  --stack-name qbusiness-public-sector \
  --parameter-overrides \
    QBusinessApplicationName="Government AI Assistant" \
    ThemeBucketName="your-unique-bucket-name" \
  --capabilities CAPABILITY_IAM
```

### Upload Theme Assets

```bash
./scripts/upload-theme-assets.sh qbusiness-public-sector
```

## Option 2: Manual Setup Script

If you already have Q Business resources, use the manual setup script:

```bash
./scripts/deploy-infrastructure.sh
```

This script will:
1. Create Secrets Manager secret with your Q Business IDs
2. Set up S3 bucket with proper policies
3. Upload theme assets
4. Configure Q Business web experience

## What Gets Created

### AWS Resources

| Resource | Purpose |
|----------|---------|
| Q Business Application | Main AI application with anonymous access |
| Q Business Web Experience | Customized web interface |
| S3 Bucket | Stores theme assets (CSS, fonts, logos) |
| Secrets Manager Secret | Securely stores Q Business IDs |
| IAM Roles | Permissions for Q Business services |

### Configuration

- **Government Theming**: Professional blue color scheme
- **Custom Assets**: Logo, fonts, favicon
- **Sample Prompts**: Government-appropriate examples
- **Session Management**: Configurable timeout

## Next Steps

After infrastructure setup:

1. Note the output values (Application ID, Web Experience ID)
2. Deploy the Amplify application using `docs/DEPLOYMENT.md`
3. Add your Amplify domain to Q Business allowed URLs

## Troubleshooting

### Common Issues

- **Bucket name conflicts**: Use a globally unique bucket name
- **Permission errors**: Ensure your AWS credentials have sufficient permissions
- **Q Business limits**: Check service quotas in your region

### Required Permissions

Your AWS credentials need permissions for:
- CloudFormation (if using template)
- Q Business (create/update applications)
- S3 (create buckets, upload objects)
- Secrets Manager (create/update secrets)
- IAM (create roles and policies)