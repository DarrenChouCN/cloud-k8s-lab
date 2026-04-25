#!/usr/bin/env bash
set -e

export TF_VAR_subscription_id=$(az account show --query id -o tsv)

echo "TF_VAR_subscription_id has been set from current Azure CLI account."
az account show --output table