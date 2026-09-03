# Scripts

Bootstrap scripts for the AKS lab.

Run from the project root.

## File order

```text
scripts/
├── 00-bootstrap-tf-backend.sh
├── 01-bootstrap-aks-addons.sh
├── 02-create-external-dns-secret.sh
├── 03-install-external-dns.sh
├── external-dns-values.yaml
└── README.md
```

## Full bootstrap flow

```bash
# 00. Prepare Terraform remote backend.
chmod +x ./scripts/00-bootstrap-tf-backend.sh
./scripts/00-bootstrap-tf-backend.sh

# 01. Initialize and apply Azure infrastructure.
export TF_VAR_subscription_id=$(az account show --query id -o tsv)
echo $TF_VAR_subscription_id

terraform -chdir=infra/terraform/environments/dev init
terraform -chdir=infra/terraform/environments/dev apply

# 02. Install common AKS add-ons.
# Includes ingress-nginx and cert-manager only.
./scripts/01-bootstrap-aks-addons.sh

# 03. Create ExternalDNS Azure config secret.
# Requires Terraform outputs and current Azure CLI login context.
./scripts/02-create-external-dns-secret.sh

# 04. Install ExternalDNS with AKS Workload Identity.
./scripts/03-install-external-dns.sh

# 05. Deploy application manifests.
kubectl apply -f k8s/sapp1/
```

## Verify add-ons

```bash
# ingress-nginx should expose a public LoadBalancer IP.
kubectl get svc -n ingress-nginx

# cert-manager pods should be Running.
kubectl get pods -n cert-manager

# external-dns pod should be Running.
kubectl get pods -n external-dns
```

## Verify ExternalDNS identity

```bash
# ServiceAccount should contain azure.workload.identity/client-id.
kubectl get sa external-dns -n external-dns -o yaml

# Pod should contain azure.workload.identity/use=true.
kubectl get pods -n external-dns --show-labels

# Logs should not show AuthorizationFailed or missing azure.json.
kubectl logs -n external-dns deploy/external-dns --tail=100
```

## Verify DNS record

```bash
# ExternalDNS should create an A record in Azure DNS.
az network dns record-set a list \
  -g rg-cloud-k8s-lab-dev-ause-01 \
  -z aks.darrencloudlab.com \
  -o table

# Domain should resolve to the ingress-nginx public IP.
nslookup sapp1.aks.darrencloudlab.com

# App should return HTTP 200.
curl -i http://sapp1.aks.darrencloudlab.com
```

## Notes

```text
ExternalDNS is installed separately because it depends on Terraform-created Azure resources:
Azure DNS Zone, managed identity, role assignment, federated identity credential, and AKS Workload Identity.

external-dns-values.yaml is not executable. It is consumed by 03-install-external-dns.sh.

ingress-nginx on AKS needs Azure Load Balancer health probe path /healthz.
Otherwise the Azure Load Balancer may mark the backend as unhealthy.
```
