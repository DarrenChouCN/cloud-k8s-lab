#!/usr/bin/env bash
set -euo pipefail

TF_DIR="infra/terraform/environments/dev"
NAMESPACE="external-dns"
EXTERNAL_DNS_VERSION="1.20.0"

EXTERNAL_DNS_CLIENT_ID=$(terraform -chdir="$TF_DIR" output -raw external_dns_client_id)

TMP_VALUES=$(mktemp)

cat > "$TMP_VALUES" <<EOF
serviceAccount:
  create: true
  name: external-dns
  annotations:
    azure.workload.identity/client-id: "$EXTERNAL_DNS_CLIENT_ID"
EOF

helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/ || true
helm repo update

helm upgrade --install external-dns external-dns/external-dns \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --version "$EXTERNAL_DNS_VERSION" \
  -f scripts/external-dns-values.yaml \
  -f "$TMP_VALUES"

rm -f "$TMP_VALUES"