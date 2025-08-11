# Infrastructure Setup Guide

## Overview

This solution requires AWS infrastructure to be set up before deploying the Amplify application. You have two options:

## Unified Deployment Script

Use the single deployment script for all scenarios:

```bash
./scripts/deploy.sh
```

### What It Creates

The script uses CloudFormation to create:

- Q Business Application with anonymous access
- Q Business Index and Retriever
- Q Business Web Experience with government theming
- S3 bucket for theme assets with proper policies
- Secrets Manager secret with dynamic name
- IAM roles and policies

### Dynamic Resource Naming

- **Secret Name**: `qbusiness-config-{StackName}-{UniqueId}`
- **Bucket Name**: `qbusiness-theme-{timestamp}`
- **Stack Name**: `qbusiness-public-sector` (default)

### For Existing Resources

If you have existing Q Business resources, the script will:
1. Create Secrets Manager secret with dynamic name
2. Set up S3 bucket with proper policies
3. Upload theme assets
4. Configure your web experience with government styling

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