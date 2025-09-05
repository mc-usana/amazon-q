# Secure Web Experiences for Amazon Q Business with AWS Amplify

*Themeable Embedded Web Experiences for Public Sector Use Cases*

[![License](https://img.shields.io/badge/License-MIT--0-blue.svg)](LICENSE)
[![Node.js](https://img.shields.io/badge/Node.js-22+-green.svg)](https://nodejs.org/)
[![AWS Amplify](https://img.shields.io/badge/AWS-Amplify-orange.svg)](https://aws.amazon.com/amplify/)

## Introduction

This scalable solution provides a customized Amazon Q Business web application designed to help public sector agencies securely accelerate their adoption of Generative AI. Built with AWS Amplify Compute, it enables server-side rendering for dynamic anonymous session generation while providing zero-infrastructure management and automatic CI/CD deployment from GitHub.

The application features **[custom theming](docs/CUSTOMIZATION.md)** for organizational branding and **automatic session management** that creates new **[anonymous chat sessions](https://docs.aws.amazon.com/amazonq/latest/qbusiness-ug/using-web-experience.html#web-experience-anonymous)** for each user visit.

By leveraging Amazon Q Business's [anonymous web experience URLs](https://docs.aws.amazon.com/amazonq/latest/api-reference/API_CreateAnonymousWebExperienceUrl.html), the solution provides secure, temporary access without requiring user authentication.  

![Government AI Assistant](docs/images/amz-q-business-embedded-themed-homepage.png)

## Getting Started

#### Prerequisites:
- AWS Account with appropriate permissions
- Node.js 22+ installed locally
- AWS CLI configured
- Git repository

## Setup

**Step 1: Clone and push to your repository:**
```bash
git clone https://github.com/aws-samples/sample-secure-web-experiences-for-amazon-q-business.git
cd sample-secure-web-experiences-for-amazon-q-business
git remote set-url origin https://github.com/YOUR_USERNAME/YOUR_NEW_REPO.git
git push -u origin main
npm install
```

**Step 2: Deploy the infrastructure.**

Deployment takes approximately 5-10 minutes.

```bash
./scripts/deploy.sh [stack-name] [branch] [github-repo] [github-token] [theme-dir]
```

**Parameters:**
- `stack-name` (optional): CloudFormation stack name (default: "qbusiness-public-sector")
- `branch` (optional): Git branch name (default: "main") 
- `github-repo` (optional): Your GitHub repository URL (e.g., "https://github.com/username/repo")
- `github-token` (optional): GitHub personal access token ([create one here](https://github.com/settings/personal-access-tokens)) for automatic deployment
- `theme-dir` (optional): Theme directory name from `assets/themes/` (default: "public-sector")

**Example with custom theme:**
```bash
./scripts/deploy.sh qbusiness-public-sector main "https://github.com/myusername/my-repo" "ghp_xxxxxxxxxxxx" "healthcare"
```

**Example with GitHub integration:**
```bash
./scripts/deploy.sh qbusiness-public-sector main "https://github.com/myusername/my-repo" "ghp_xxxxxxxxxxxx"
```
*Note: Without GitHub integration, this creates Q Business infrastructure and local .env file for development, but no Amplify deployment.*

The script will guide you through setup:

```
🏛️  AMAZON Q BUSINESS DEPLOYMENT

⏱️  Estimated deployment time: ~10 minutes

─ CONFIGURATION ──────────────────────────────────────────────────────────────

📦 Stack Name: qbusiness-public-sector
🌿 Branch: main
🌍 Region: us-east-1

─ APPLICATION SETUP ──────────────────────────────────────────────────────────

Application name [GovernmentAIAssistant]: My Agency Assistant
✅ Application name validated: My Agency Assistant

─ INFRASTRUCTURE DEPLOYMENT ──────────────────────────────────────────────────

🚀 Deploying CloudFormation stack...
...
✅ Infrastructure deployed successfully!

─ THEME ASSETS ───────────────────────────────────────────────────────────────

Uploading custom theme assets...
✅ Theme assets uploaded successfully

─ DEPLOYMENT SUMMARY ─────────────────────────────────────────────────────────

+---------------------------+-----------------------------------------------------------------------------+
|  AmplifyComputeRoleArn    |  arn:aws:iam::123456789012:role/qbusiness-public-sector-AmplifyComputeRole  |
|  QBusinessApplicationId   |  abcd1234-5678-90ef-ghij-klmnopqrstuv                                       |
|  QBusinessWebExperienceId |  abcd1234-5678-90ef-ghij-klmnopqrstuv|wxyz5678-90ab-cdef-1234-567890abcdef  |
|  SecretsManagerSecretName |  qbusiness-webexperience-config                                              |
|  AmplifyDefaultDomain     |  https://main.d1a2b3c4d5e6f7.amplifyapp.com                                 |
+---------------------------+-----------------------------------------------------------------------------+

🎉 DEPLOYMENT COMPLETE!

NEXT STEPS:
   1. Visit your AmplifyDefaultDomain to verify deployment
   2. Test locally: npm install && npm start

✨ Thank you for using Amazon Q Business!
```

**Step 3: Test locally (optional).**

```bash
npm install && npm start
```

Visit `http://localhost:3000` to test locally.

**Note**: Your Amplify app will auto-deploy when changes are committed to the main branch.

**Production Security**: For production deployments, remove `http://localhost:3000` from the `DeveloperOrigins` parameter in your CloudFormation stack to prevent local development access.

## Reference Architecture

![Q Business with AWS Amplify Architecture](docs/images/q-business-with-aws-amplify-architecture-diagram.png)

Built with Express.js and deployed on AWS Amplify using CloudFormation for infrastructure management, this demo solution creates a secure, themed Q Business deployment with the following components:

- **Q Business Application**: Anonymous access with custom theming
- **Web Experience**: Customized branding and styling
- **Amplify Hosting**: Server-side rendering with Express.js
- **WAF (Web Application Firewall)**: Security protection for the web application
- **Secrets Manager**: Secure storage of Q Business configuration
- **S3 Bucket**: Theme assets (CSS, fonts, logos)
- **IAM Roles**: Least-privilege permissions for Amplify compute

## Project Structure

```
qbamplify/
├── assets/                 # Theme assets (CSS, fonts, logos)
├── config/                 # Configuration files
├── docs/                   # Documentation
├── infrastructure/         # CloudFormation templates
├── scripts/                # Build and deployment scripts
└── src/                    # Express.js application
```

## Amplify GitHub App Migration

After deployment, you may see this message in the AWS Amplify console:

![Amplify GitHub App Migration](docs/images/amplify-Migrate-to-our-GitHub-app-message.png)

**Recommendation**: Click the "Start migration" button to migrate to the new GitHub App integration. Use a GitHub app instead of OAuth to access your code repository to trigger builds. GitHub apps offer the same experience but with fewer required permissions.

## Cleanup

To remove all AWS resources created by this solution:

```bash
./scripts/cleanup.sh [stack-name]
```

**Parameters:**
- `stack-name` (optional): CloudFormation stack name to delete (default: "qbusiness-public-sector")

**Example:**
```bash
./scripts/cleanup.sh
```

The script will:
1. Empty the S3 theme assets bucket (all versions)
2. Delete the Secrets Manager secret
3. Delete the CloudFormation stack and all associated resources

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.

## License

This project is licensed under the MIT-0 License. See [LICENSE](LICENSE) for details.

## Security

See [CONTRIBUTING.md](CONTRIBUTING.md#security-issue-notifications) for security issue reporting.