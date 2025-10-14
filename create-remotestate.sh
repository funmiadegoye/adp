#!/bin/bash

BUCKET_NAME="funmi-2025"
AWS_PROFILE="tutu"
AWS_REGION="eu-west-2"

# =========================
# Destroy vault-jenkins infrastructure
# =========================
if [ -d "vault-jenkins" ]; then
  echo "🛑 Destroying vault-jenkins infrastructure with Terraform..."
  cd vault-jenkins
  terraform destroy -auto-approve
  cd ..
else
  echo "⚠️  Directory vault-jenkins not found. Skipping Terraform destroy."
fi

echo "⚠️  Deleting Terraform state bucket: $BUCKET_NAME in region: $AWS_REGION (profile: $AWS_PROFILE)"

# List all object versions and delete markers
DELETE_LIST=$(aws s3api list-object-versions \
  --bucket "$BUCKET_NAME" \
  --profile "$AWS_PROFILE" \
  --region "$AWS_REGION" \
  --output json)

# Extract objects to delete using jq and set as a variable
OBJECTS_TO_DELETE=$(echo "$DELETE_LIST" | jq '{
  Objects: (
    [.Versions[]?, .DeleteMarkers[]?]
    | map({Key: .Key, VersionId: .VersionId})
  ),
  Quiet: true
}')

# Count number of deletable items and set as a variable
NUM_OBJECTS=$(echo "$OBJECTS_TO_DELETE" | jq '.Objects | length')

# Delete objects if there are any
if [ "$NUM_OBJECTS" -gt 0 ]; then
  echo "Deleting $NUM_OBJECTS objects from bucket: $BUCKET_NAME..."
  aws s3api delete-objects \
    --bucket "$BUCKET_NAME" \
    --delete "$OBJECTS_TO_DELETE" \
    --region "$AWS_REGION" \
    --profile "$AWS_PROFILE"
  echo "Object deletion complete."
else
  echo "No objects or versions found in $BUCKET_NAME."
fi

# Attempt to delete the empty bucket
echo "Deleting bucket: $BUCKET_NAME..."
aws s3api delete-bucket \
  --bucket "$BUCKET_NAME" \
  --region "$AWS_REGION" \
  --profile "$AWS_PROFILE"

echo "Bucket $BUCKET_NAME deleted successfully."