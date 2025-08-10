# Deployment Overview

This guide provides an overview of the deployment process. For detailed instructions, see the specific guides below.

## Setup Paths

### Option 1: Existing Q Business Resources
If you already have Q Business Application ID and Web Experience ID:

**[→ Setup with Existing Resources](SETUP_EXISTING.md)**

### Option 2: New Q Business Resources
If you need to create Q Business resources from scratch:

**[→ Setup with New Resources](SETUP_NEW.md)**

## Deployment Steps

After completing setup:

1. **Configure**: Follow one of the setup guides above
2. **Deploy**: Use the [AWS Amplify Deployment Guide](AMPLIFY_SETUP.md)
3. **Customize**: Follow the [Theme Customization Guide](CUSTOMIZATION.md)

## Key Files

- `config/.env` - Environment variables
- `config/amplify.yml` - Amplify build configuration
- `infrastructure/cloudformation.yaml` - Complete infrastructure setup
- `scripts/build.sh` - Build script for Amplify

## Quick Test

```bash
npm install
npm start
```

Visit `http://localhost:3000` to test locally.