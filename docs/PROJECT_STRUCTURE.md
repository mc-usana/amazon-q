# Project Structure

This project follows AWS coding best practices with a standardized directory structure:

```
qbamplify/
├── src/                    # Source code
│   ├── index.js           # Main Express application
│   ├── secrets.js         # AWS Secrets Manager integration
│   ├── styles.css         # Application styling
│   └── utils.js           # Utility functions
├── config/                 # Configuration files
│   ├── .env               # Environment variables
│   ├── amplify.yml        # AWS Amplify configuration
│   ├── deploy-manifest.json # Deployment manifest
│   └── s3-bucket-policy.json # S3 bucket policy template
├── scripts/                # Build and deployment scripts
│   ├── build.sh           # Amplify build script
│   ├── setup.sh           # Q Business setup script
│   └── upload-theme-assets.sh # Theme upload script
├── assets/                 # Static assets
│   ├── AmazonEmber_Bd.ttf # Amazon font
│   ├── aws-logo.png       # Logo
│   ├── favicon.ico        # Favicon
│   └── public-sector-theme.css # Government theme
├── infrastructure/         # CloudFormation templates
│   └── cloudformation.yaml # Complete infrastructure setup
├── docs/                   # Documentation
│   ├── images/            # Documentation images
│   ├── DEPLOYMENT.md      # Deployment guide
│   ├── INFRASTRUCTURE.md  # Infrastructure setup guide
│   └── PROJECT_STRUCTURE.md # This file
├── to_be_deleted/          # Non-essential files (safe to remove)
├── package.json            # Node.js dependencies
├── package-lock.json       # Dependency lock file
├── .gitignore             # Git ignore rules
├── README.md              # Main documentation
├── LICENSE                # MIT-0 License
├── CONTRIBUTING.md        # Contributing guidelines
├── CODE_OF_CONDUCT.md     # Code of conduct
└── CLEANUP-SUMMARY.md     # Cleanup summary
```

## Directory Descriptions

### `/src`
Contains the main application source code following Node.js best practices.

### `/config`
Configuration files separated from source code for better security and maintainability.

### `/scripts`
Build, deployment, and utility scripts following AWS DevOps practices.

### `/infrastructure`
CloudFormation templates and Infrastructure as Code (IaC) files.

### `/assets`
Static assets like fonts, images, and CSS files.

### `/docs`
All documentation including images, guides, and project information.

### `/to_be_deleted`
Contains files moved during cleanup that can be safely removed.

## Benefits of This Structure

1. **Separation of Concerns**: Clear separation between source code, configuration, and assets
2. **Security**: Configuration files isolated from source code
3. **Maintainability**: Logical organization makes the project easier to navigate
4. **AWS Standards**: Follows AWS coding best practices and conventions
5. **Scalability**: Structure supports project growth and additional components