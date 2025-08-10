# AWS Amplify Deployment

Deploy your Q Business web application to AWS Amplify with server-side rendering.

## Prerequisites

- Q Business resources configured (see setup guides)
- Git repository
- AWS Amplify access

## Deployment Steps

### 1. Push to Git Repository

```bash
git add .
git commit -m "Initial commit"
git push origin main
```

### 2. Create Amplify App

1. Open [AWS Amplify Console](https://console.aws.amazon.com/amplify/)
2. Choose **Create new app** → **Host web app**
3. Connect your Git repository
4. Select repository and branch
5. The `config/amplify.yml` file will be automatically detected

### 3. Configure IAM Role

Create an IAM role for Amplify with these permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "qbusiness:CreateAnonymousWebExperienceUrl",
      "Resource": [
        "arn:aws:qbusiness:*:*:application/YOUR_APP_ID",
        "arn:aws:qbusiness:*:*:application/YOUR_APP_ID/web-experience/YOUR_WEB_EXP_ID"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "qbusiness:Chat",
        "qbusiness:ChatSync", 
        "qbusiness:PutFeedback"
      ],
      "Resource": "arn:aws:qbusiness:*:*:application/YOUR_APP_ID"
    },
    {
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "arn:aws:secretsmanager:*:*:secret:qbusiness-config*"
    }
  ]
}
```

### 4. Attach IAM Role

1. In Amplify Console → **App settings** → **IAM roles**
2. Select **Compute role**
3. Choose your created IAM role

### 5. Deploy

Click **Save and deploy** to start the deployment.

## Post-Deployment

### Add Domain to Q Business

1. Copy your Amplify app URL (e.g., `https://main.d1abc123.amplifyapp.com`)
2. Go to [Q Business Console](https://console.aws.amazon.com/qbusiness/)
3. Select your application → **Web experiences**
4. Add your Amplify domain to allowed URLs

### Environment Variables (Optional)

Set in Amplify Console if different from defaults:

| Variable | Description | Default |
|----------|-------------|---------|
| `CUSTOMIZE_WEB_EXPERIENCE` | Enable customization | `true` |
| `SESSION_DURATION_MINUTES` | Session timeout | `15` |

## Troubleshooting

### Common Issues

- **403 Errors**: Check IAM role permissions
- **Build Failures**: Verify Node.js version (18+)
- **Domain Issues**: Ensure domain is added to Q Business allowed URLs

### Logs

- **Build logs**: Available in Amplify Console
- **Runtime logs**: Check CloudWatch logs for your Amplify app

## Custom Domain (Optional)

1. In Amplify Console → **Domain management**
2. Add your custom domain
3. Update Q Business allowed URLs with your custom domain