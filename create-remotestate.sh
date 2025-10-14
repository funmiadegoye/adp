#!/bin/bash

# Set your bucket name and region
BUCKET_NAME="funmi-2025"
AWS_REGION="eu-west-2"
AWS_PROFILE="tutu"

echo "🚀 Creating Terraform state bucket: $BUCKET_NAME in region: $AWS_REGION (profile: $AWS_PROFILE)"

# =========================
# Create S3 bucket
# =========================
aws s3api create-bucket \
  --bucket "$BUCKET_NAME" \
  --region "$AWS_REGION" \
  --profile "$AWS_PROFILE" \
  --create-bucket-configuration LocationConstraint="$AWS_REGION"

# =========================
# Enable versioning
# =========================
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --region "$AWS_REGION" \
  --profile "$AWS_PROFILE" \
  --versioning-configuration Status=Enabled

echo "✅ Versioning enabled"

# =========================
# Run Terraform workflow for vault-jenkins
# =========================
cd vault-jenkins || { echo "❌ Directory vault-jenkins not found!"; exit 1; }

echo "🚀 Initializing and applying Terraform for vault-jenkins..."

terraform init
terraform fmt --recursive
terraform apply -auto-approve

echo "🎉 Terraform state bucket configured and vault-jenkins infrastructure created successfully!"