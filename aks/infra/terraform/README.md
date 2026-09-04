# AKS Terraform Deployment

Terraform configuration for provisioning Azure infrastructure and bootstrapping Argo CD into the AKS cluster.

## Architecture

The Terraform workflow is separated into two independent root modules:

```text
infra/terraform/
├── environments/
│   └── dev/          # Azure infrastructure + AKS
│
└── bootstrap/
    └── dev/          # Helm Provider + Argo CD
```

Each root module maintains its own Terraform state.

```text
Infrastructure state:
aks/dev/terraform.tfstate

Bootstrap state:
aks/bootstrap/dev/terraform.tfstate
```

Deployment flow:

```text
Terraform Infrastructure
        ↓
Azure Resources + AKS
        ↓
Terraform Bootstrap
        ↓
Helm Provider
        ↓
Argo CD
```

---

## 1. Install Terraform

```bash
sudo apt-get update
sudo apt-get install -y gnupg software-properties-common wget lsb-release

wget -O- https://apt.releases.hashicorp.com/gpg \
  | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt-get update
sudo apt-get install -y terraform

terraform --version
terraform -install-autocomplete
```

---

## 2. Bootstrap Terraform Backend

Run from the project root:

```bash
./scripts/00-bootstrap-tf-backend.sh
```

The Azure Storage backend is shared by both Terraform root modules, while each module uses a different state key.

---

## 3. Configure Development Variables

```bash
cd aks/infra/terraform/environments/dev
cp terraform.tfvars.bak terraform.tfvars
```

Update `terraform.tfvars` with the required environment-specific values.

`terraform.tfvars` is ignored by Git and should not be committed.

Set the current Azure subscription ID for the shell session:

```bash
export TF_VAR_subscription_id=$(az account show --query id -o tsv)
```

Verify:

```bash
echo $TF_VAR_subscription_id
```

---

## 4. Deploy Azure Infrastructure

```bash
cd aks/infra/terraform/environments/dev

terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

This stage provisions the Azure infrastructure, including:

- Resource Group
- AKS Cluster
- Azure Container Registry
- Azure DNS Zone
- ExternalDNS Managed Identity
- Azure RBAC assignments
- AKS Workload Identity and federated identity configuration

---

## 5. Bootstrap Argo CD

After the AKS cluster has been successfully created:

```bash
cd aks/infra/terraform/bootstrap/dev

terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

The bootstrap Terraform configuration:

1. Reads the existing AKS cluster using an AzureRM data source.
2. Retrieves the AKS Kubernetes connection configuration.
3. Configures the Terraform Helm Provider.
4. Installs Argo CD using the official Argo CD Helm chart.

Bootstrap flow:

```text
Terraform
   ↓
AzureRM Data Source
   ↓
Existing AKS Cluster
   ↓
Helm Provider
   ↓
Argo CD Helm Release
```

---

## 6. Connect to AKS

```bash
az aks get-credentials \
  --resource-group rg-cloud-k8s-lab-dev-ause-01 \
  --name aks-cloud-k8s-lab-dev-ause-01
```

If an existing kubeconfig entry needs to be replaced:

```bash
az aks get-credentials \
  --resource-group rg-cloud-k8s-lab-dev-ause-01 \
  --name aks-cloud-k8s-lab-dev-ause-01 \
  --overwrite-existing
```

---

## 7. Verify Argo CD

Verify the namespace:

```bash
kubectl get ns
```

Verify the Argo CD workloads:

```bash
kubectl get pods -n argocd
```

Expected components include:

```text
argocd-application-controller
argocd-applicationset-controller
argocd-dex-server
argocd-notifications-controller
argocd-redis
argocd-repo-server
argocd-server
```

All pods should reach the `Running` state.

Verify the Helm release:

```bash
helm list -n argocd
```

The Argo CD release should report:

```text
STATUS: deployed
```

---

## Terraform Responsibility Boundary

Terraform is responsible for:

```text
Azure infrastructure
AKS
Azure identities and RBAC
Argo CD bootstrap
```

Argo CD will be responsible for Kubernetes-level platform components and application workloads.

Future cluster add-ons such as:

```text
ingress-nginx
cert-manager
ExternalDNS
```

will be migrated from shell-script installation to declarative GitOps management through Argo CD.