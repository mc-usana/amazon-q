#!/bin/bash

# Create output directory if it doesn't exist
mkdir -p _aws_deliverable_security_review_assets

echo "Installing/running Automated Security Helper (ASH) v3..."

# Check if uv is installed
if ! command -v uv &> /dev/null; then
    echo "Installing uv package manager..."
    curl -sSf https://astral.sh/uv/install.sh | sh
    source ~/.bashrc
fi

# Run ASH using uvx
echo "Running security scan..."
uvx git+https://github.com/awslabs/automated-security-helper.git@v3.0.0 \
    --source-dir . \
    --output-dir _aws_deliverable_security_review_assets

echo "Security scan complete. Results saved to: _aws_deliverable_security_review_assets/"
