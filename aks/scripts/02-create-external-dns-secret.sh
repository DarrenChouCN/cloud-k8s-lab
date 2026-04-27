#!/usr/bin/env bash
set -euo pipefail

TF_DIR="infra/terraform/environments/dev"
NAMESPACE="external-dns"
SECRET_NAME="external-dns-azure"

TENANT_ID=$(az account show --query tenantId -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
DNS_RG=$(terraform -chdir="$TF_DIR" output -raw resource_group_name)

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

TMP_FILE=$(mktemp)

cat > "$TMP_FILE" <<EOF
{
  "tenantId": "$TENANT_ID",
  "subscriptionId": "$SUBSCRIPTION_ID",
  "resourceGroup": "$DNS_RG",
  "useWorkloadIdentityExtension": true
}
EOF

kubectl create secret generic "$SECRET_NAME" \
  -n "$NAMESPACE" \
  --from-file=azure.json="$TMP_FILE" \
  --dry-run=client -o yaml | kubectl apply -f -

rm -f "$TMP_FILE"

echo "Created secret: $SECRET_NAME in namespace: $NAMESPACE"