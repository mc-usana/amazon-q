# Deployment Overview

This guide provides an overview of the deployment process. For detailed instructions, see the specific guides below.

## Quick Start

Use the unified deployment script:

```bash
./scripts/deploy.sh
```

The script will ask if you have existing Q Business resources and guide you through the appropriate setup.

## Setup Paths

### Option 1: Existing Q Business Resources
**[→ Setup with Existing Resources](SETUP_EXISTING.md)**

### Option 2: New Q Business Resources  
**[→ Setup with New Resources](SETUP_NEW.md)**

## Deployment Steps

1. **Deploy**: Run `./scripts/deploy.sh`
2. **Test**: Run `npm install && npm start`
3. **Deploy to Amplify**: Follow [AWS Amplify Deployment Guide](AMPLIFY_SETUP.md)
4. **Customize**: Follow [Theme Customization Guide](CUSTOMIZATION.md)

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