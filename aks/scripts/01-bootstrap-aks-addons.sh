#!/usr/bin/env bash

set -euo pipefail

# =========================
# AKS target configuration
# =========================

RG="<resource-group>"
AKS="<aks-name>"

# =========================
# Helm chart versions
# =========================

INGRESS_NGINX_VERSION="4.15.1"
CERT_MANAGER_VERSION="v1.20.2"

# =========================
# Helm repository URLs
# =========================

INGRESS_NGINX_REPO_NAME="ingress-nginx"
INGRESS_NGINX_REPO_URL="https://kubernetes.github.io/ingress-nginx"

CERT_MANAGER_REPO_NAME="jetstack"
CERT_MANAGER_REPO_URL="https://charts.jetstack.io"

# =========================
# Connect to AKS
# =========================

echo "Connecting kubectl and Helm to AKS..."

az aks get-credentials \
  --resource-group "$RG" \
  --name "$AKS" \
  --overwrite-existing

echo "Current Kubernetes context:"
kubectl config current-context

echo "Checking AKS nodes:"
kubectl get nodes

# =========================
# Add Helm repositories
# =========================

echo "Adding Helm repositories..."

helm repo add "$INGRESS_NGINX_REPO_NAME" "$INGRESS_NGINX_REPO_URL"
helm repo add "$CERT_MANAGER_REPO_NAME" "$CERT_MANAGER_REPO_URL"

echo "Updating Helm repository index..."
helm repo update

echo "Current Helm repositories:"
helm repo list

# =========================
# Install ingress-nginx
# =========================

echo "Installing ingress-nginx..."

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --version "$INGRESS_NGINX_VERSION" \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz

# =========================
# Install cert-manager
# =========================

echo "Installing cert-manager..."

helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version "$CERT_MANAGER_VERSION" \
  --set crds.enabled=true

# =========================
# Verify installation
# =========================

echo "Checking Helm releases..."
helm list -A

echo "Checking ingress-nginx pods..."
kubectl get pods -n ingress-nginx

echo "Checking cert-manager pods..."
kubectl get pods -n cert-manager

echo "Checking ingress-nginx LoadBalancer service..."
kubectl get svc -n ingress-nginx

echo "AKS addon bootstrap completed."