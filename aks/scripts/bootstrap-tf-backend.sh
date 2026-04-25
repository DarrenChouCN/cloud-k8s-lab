#!/usr/bin/env bash
set -euo pipefail

# Backend settings
BACKEND_RG="${BACKEND_RG:-rg-tfstate-cloud-k8s-lab-ause-01}"
LOCATION="${LOCATION:-australiasoutheast}"
CONTAINER_NAME="${CONTAINER_NAME:-tfstate}"
STATE_KEY="${STATE_KEY:-aks/dev/terraform.tfstate}"

# Check Azure login
az account show >/dev/null || {
  echo "Azure CLI is not logged in. Run: az login"
  exit 1
}

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)

# Generate a deterministic storage account name from subscription ID
# Storage account name must be globally unique, lowercase, and 3-24 chars.
SUFFIX=$(printf "%s" "$SUBSCRIPTION_ID" | sha1sum | cut -c1-6)
SA_NAME="${TFSTATE_STORAGE_ACCOUNT_NAME:-tfstatek8s${SUFFIX}}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEV_DIR="${SCRIPT_DIR}/../infra/terraform/environments/dev"

echo "Using subscription: ${SUBSCRIPTION_NAME}"
echo "Backend resource group: ${BACKEND_RG}"
echo "Backend storage account: ${SA_NAME}"
echo "Backend container: ${CONTAINER_NAME}"
echo "State key: ${STATE_KEY}"
echo

# Create backend resource group
az group create \
  --name "$BACKEND_RG" \
  --location "$LOCATION" \
  --output none

# Create storage account if it does not exist
if az storage account show \
  --name "$SA_NAME" \
  --resource-group "$BACKEND_RG" \
  >/dev/null 2>&1; then
  echo "Storage account already exists: ${SA_NAME}"
else
  echo "Creating storage account: ${SA_NAME}"

  az storage account create \
    --name "$SA_NAME" \
    --resource-group "$BACKEND_RG" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --access-tier Hot \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false \
    --output none
fi

# Create blob container
ACCOUNT_KEY=$(az storage account keys list \
  --account-name "$SA_NAME" \
  --resource-group "$BACKEND_RG" \
  --query "[0].value" \
  -o tsv)

az storage container create \
  --name "$CONTAINER_NAME" \
  --account-name "$SA_NAME" \
  --account-key "$ACCOUNT_KEY" \
  --output none

# Grant current user Blob Data Contributor permission
USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)

STORAGE_ID=$(az storage account show \
  --name "$SA_NAME" \
  --resource-group "$BACKEND_RG" \
  --query id \
  -o tsv)

ROLE_COUNT=$(az role assignment list \
  --assignee "$USER_OBJECT_ID" \
  --role "Storage Blob Data Contributor" \
  --scope "$STORAGE_ID" \
  --query "length(@)" \
  -o tsv)

if [ "$ROLE_COUNT" = "0" ]; then
  echo "Assigning Storage Blob Data Contributor role..."

  az role assignment create \
    --assignee "$USER_OBJECT_ID" \
    --role "Storage Blob Data Contributor" \
    --scope "$STORAGE_ID" \
    --output none
else
  echo "Storage Blob Data Contributor role already exists."
fi

# Generate backend.tf
cat > "${DEV_DIR}/backend.tf" <<EOF
terraform {
  backend "azurerm" {
    resource_group_name  = "${BACKEND_RG}"
    storage_account_name = "${SA_NAME}"
    container_name       = "${CONTAINER_NAME}"
    key                  = "${STATE_KEY}"
    use_azuread_auth     = true
  }
}
EOF

echo
echo "Backend config generated:"
echo "${DEV_DIR}/backend.tf"
echo
echo "Next steps:"
echo "cd ${DEV_DIR}"
echo "terraform init -migrate-state"