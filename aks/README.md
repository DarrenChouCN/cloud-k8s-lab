# AKS GitOps Platform — Live Demo Runbook

This repository demonstrates a production-style AKS delivery platform built with Terraform, Argo CD, Azure Workload Identity, ExternalDNS, ingress-nginx, and cert-manager.

This README is designed for a **live interview walkthrough of an environment that is already deployed**. The commands below query the real environment without rebuilding it.

> Run all commands from the `aks/` directory. Do not run `terraform apply` during the demo.

## Architecture



### Ownership boundary

| Layer | Owner | Main resources |
|---|---|---|
| Azure infrastructure | Terraform | Resource group, AKS, ACR, Azure DNS, identities and RBAC |
| GitOps bootstrap | Terraform | Argo CD and the root `argocd-apps` release |
| Platform services | Argo CD | ingress-nginx, cert-manager and ExternalDNS |
| Application workloads | Argo CD | sapp1 and sapp2 Deployments, Services and Ingresses |
| Public delegation | Domain registrar | One-time delegation of `aks.darrencloudlab.com` to Azure DNS |

## Demo preparation

The workstation requires Azure CLI, Terraform, kubectl, Helm, curl, dig and OpenSSL. Azure CLI must be authenticated and kubectl must point to the deployed AKS cluster.

Set reusable variables once:

```bash
TF_ENV_DIR="infra/terraform/environments/dev"
TF_BOOTSTRAP_DIR="infra/terraform/bootstrap/dev"

RG_NAME=$(terraform -chdir="$TF_ENV_DIR" output -raw resource_group_name)
AKS_NAME=$(terraform -chdir="$TF_ENV_DIR" output -raw aks_cluster_name)
ACR_NAME=$(terraform -chdir="$TF_ENV_DIR" output -raw acr_name)
DNS_ZONE=$(terraform -chdir="$TF_ENV_DIR" output -raw dns_zone_name)
EXTDNS_IDENTITY=$(terraform -chdir="$TF_ENV_DIR" output -raw external_dns_identity_name)
```

Confirm the active Azure subscription and Kubernetes context:

```bash
az account show --query '{Subscription:name,User:user.name}' -o table
kubectl config current-context
kubectl cluster-info
```

## 1. Show the Terraform-managed Azure foundation

Display the resources tracked by the environment state:

```bash
terraform -chdir="$TF_ENV_DIR" state list
```

Display the deployed Azure resources:

```bash
az resource list \
  --resource-group "$RG_NAME" \
  --query '[].{Name:name,Type:type,Location:location}' \
  -o table
```

Confirm AKS health, OIDC and Workload Identity:

```bash
az aks show \
  --resource-group "$RG_NAME" \
  --name "$AKS_NAME" \
  --query '{Name:name,State:provisioningState,Kubernetes:kubernetesVersion,OIDC:oidcIssuerProfile.enabled,WorkloadIdentity:securityProfile.workloadIdentity.enabled,NodeResourceGroup:nodeResourceGroup}' \
  -o yaml
```

Confirm the ACR and Azure DNS Zone:

```bash
az acr show \
  --resource-group "$RG_NAME" \
  --name "$ACR_NAME" \
  --query '{Name:name,LoginServer:loginServer,SKU:sku.name,AdminEnabled:adminUserEnabled}' \
  -o yaml

az network dns zone show \
  --resource-group "$RG_NAME" \
  --name "$DNS_ZONE" \
  --query '{Zone:name,NameServers:nameServers}' \
  -o yaml
```

**Talk track:** Terraform owns the cloud foundation and identity boundaries. The ACR admin account is disabled; AKS pulls images through its kubelet managed identity.

## 2. Prove AKS-to-ACR access without registry credentials

Show the images stored in ACR:

```bash
az acr repository list --name "$ACR_NAME" -o table
az acr repository show-tags --name "$ACR_NAME" --repository sapp1 -o table
az acr repository show-tags --name "$ACR_NAME" --repository sapp2 -o table
```

Show the `AcrPull` assignment granted to the AKS kubelet identity:

```bash
KUBELET_OBJECT_ID=$(az aks show \
  --resource-group "$RG_NAME" \
  --name "$AKS_NAME" \
  --query identityProfile.kubeletidentity.objectId \
  -o tsv)

ACR_RESOURCE_ID=$(az acr show \
  --resource-group "$RG_NAME" \
  --name "$ACR_NAME" \
  --query id \
  -o tsv)

az role assignment list \
  --assignee-object-id "$KUBELET_OBJECT_ID" \
  --scope "$ACR_RESOURCE_ID" \
  --query '[].{Role:roleDefinitionName,Scope:scope}' \
  -o table
```

Optional active connectivity check:

```bash
az aks check-acr \
  --resource-group "$RG_NAME" \
  --name "$AKS_NAME" \
  --acr "${ACR_NAME}.azurecr.io"
```

**Talk track:** Native Kubernetes often needs an `imagePullSecret` for a private registry. AKS instead uses the kubelet managed identity with the least-privilege `AcrPull` role.

## 3. Show the Terraform bootstrap boundary

Terraform installs only the GitOps control plane and its root configuration:

```bash
terraform -chdir="$TF_BOOTSTRAP_DIR" state list
helm list --namespace argocd
kubectl --namespace argocd get deployments,pods
```

Expected Terraform-managed Helm releases:

- `argocd`: installs Argo CD itself.
- `argocd-bootstrap`: installs the root ApplicationSet definitions through the `argocd-apps` chart.

**Talk track:** Terraform stops at the bootstrap boundary. After Argo CD is available, in-cluster platform components and workloads are reconciled continuously from Git.

## 4. Show ApplicationSet discovery and reconciliation

Display the two independent ApplicationSets:

```bash
kubectl --namespace argocd get applicationsets

kubectl --namespace argocd get applicationset platform \
  -o jsonpath='{.spec.generators[0].git.files[0].path}{"\n"}'

kubectl --namespace argocd get applicationset workloads \
  -o jsonpath='{.spec.generators[0].git.directories[0].path}{"\n"}'
```

Expected discovery paths:

```text
aks/gitops/platform/*/config.yaml
aks/gitops/apps/*
```

Show every generated Argo CD Application:

```bash
kubectl --namespace argocd get applications
```

Expected result: `cert-manager`, `external-dns`, `ingress-nginx`, `sapp1` and `sapp2` are all `Synced` and `Healthy`.

Inspect the multi-source ExternalDNS Application:

```bash
kubectl --namespace argocd get application external-dns \
  -o jsonpath='{range .spec.sources[*]}{.repoURL}{"  chart="}{.chart}{"  path="}{.path}{"\n"}{end}'
```

**Talk track:** Platform components use a file generator because each component supplies chart metadata, values and optional manifests. Workloads use a directory generator because each application is a directory of plain Kubernetes manifests.

## 5. Show the platform add-ons

```bash
kubectl --namespace ingress-nginx get deployments,services,pods
kubectl --namespace cert-manager get deployments,pods
kubectl --namespace external-dns get deployments,pods,serviceaccounts
kubectl get clusterissuer
```

Show the public ingress address:

```bash
kubectl --namespace ingress-nginx get service ingress-nginx-controller
```

**Talk track:** ingress-nginx provides the shared public entry point, ExternalDNS publishes Ingress hostnames into Azure DNS, and cert-manager automates public certificate issuance through Let’s Encrypt.

> Argo CD renders the upstream Helm charts and owns the resulting Kubernetes resources. These platform components are therefore visible as Argo CD Applications rather than independent local Helm releases.

## 6. Prove ExternalDNS uses Azure Workload Identity

Show the Kubernetes side of the trust relationship:

```bash
kubectl --namespace external-dns get serviceaccount external-dns \
  -o jsonpath='{.metadata.annotations.azure\.workload\.identity/client-id}{"\n"}'

kubectl --namespace external-dns get pods \
  -l app.kubernetes.io/name=external-dns \
  --show-labels
```

Show the corresponding Azure federated credential:

```bash
az identity federated-credential list \
  --resource-group "$RG_NAME" \
  --identity-name "$EXTDNS_IDENTITY" \
  --query '[].{Name:name,Issuer:issuer,Subject:subject,Audience:audiences[0]}' \
  -o table
```

Show the Azure roles assigned to ExternalDNS:

```bash
EXTDNS_PRINCIPAL_ID=$(az identity show \
  --resource-group "$RG_NAME" \
  --name "$EXTDNS_IDENTITY" \
  --query principalId \
  -o tsv)

az role assignment list \
  --assignee-object-id "$EXTDNS_PRINCIPAL_ID" \
  --all \
  --query '[].{Role:roleDefinitionName,Scope:scope}' \
  -o table
```

Check the controller logs:

```bash
kubectl --namespace external-dns logs deployment/external-dns --tail=30
```

**Talk track:** The Kubernetes ServiceAccount is federated with an Azure user-assigned identity through the AKS OIDC issuer. ExternalDNS receives short-lived tokens and needs no client secret stored in Git or Kubernetes.

## 7. Show GitOps-managed workloads

Display the resources and exact ACR images used by each workload:

```bash
kubectl --namespace sapp1 get deployments,services,ingresses,pods
kubectl --namespace sapp2 get deployments,services,ingresses,pods

kubectl --namespace sapp1 get deployment sapp1 \
  -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'

kubectl --namespace sapp2 get deployment sapp2 \
  -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
```

Show the routing configuration currently stored in the cluster:

```bash
kubectl --namespace sapp1 get ingress sapp1-ingress
kubectl --namespace sapp2 get ingress sapp2-ingress
```

**Talk track:** Each application is isolated in its own namespace. The Service remains private as `ClusterIP`; only the shared ingress controller is public.

## 8. Show automated DNS and TLS

Compare the Azure-assigned name servers with the public child-zone delegation:

```bash
terraform -chdir="$TF_ENV_DIR" output dns_zone_name_servers
dig NS "$DNS_ZONE" +short
```

Show the A records created by ExternalDNS:

```bash
az network dns record-set a list \
  --resource-group "$RG_NAME" \
  --zone-name "$DNS_ZONE" \
  --query '[].{Name:name,IPv4:aRecords[0].ipv4Address,TTL:ttl}' \
  -o table

dig sapp1.aks.darrencloudlab.com A +short
dig sapp2.aks.darrencloudlab.com A +short
```

Show certificate readiness and ACME order status:

```bash
kubectl --namespace sapp1 get certificates,certificaterequests,orders
kubectl --namespace sapp2 get certificates,certificaterequests,orders
```

Inspect the certificate served publicly:

```bash
echo | openssl s_client \
  -connect sapp1.aks.darrencloudlab.com:443 \
  -servername sapp1.aks.darrencloudlab.com 2>/dev/null | \
  openssl x509 -noout -issuer -dates -ext subjectAltName
```

**Talk track:** ExternalDNS watches Kubernetes Ingress resources and reconciles the required Azure DNS records. cert-manager then completes the HTTP-01 challenge through ingress-nginx and stores the issued certificates as Kubernetes TLS Secrets.

## 9. End-to-end public verification

```bash
curl --fail --silent --show-error --head \
  https://sapp1.aks.darrencloudlab.com

curl --fail --silent --show-error --head \
  https://sapp2.aks.darrencloudlab.com
```

Public endpoints:

- [sapp1](https://sapp1.aks.darrencloudlab.com)
- [sapp2](https://sapp2.aks.darrencloudlab.com)

The complete request path is:

```text
Public DNS → Azure Load Balancer → ingress-nginx → ClusterIP Service → application Pod
```

### 10. Monitoring Demo — Prometheus & Grafana

Check monitoring status:

```bash
kubectl get application kube-prometheus-stack -n argocd
kubectl get pods,pvc -n monitoring
```

Open Grafana (keep this terminal running):

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
```

In another terminal, retrieve the password:

```bash
kubectl get secret -n monitoring kube-prometheus-stack-grafana -o jsonpath='{.data.admin-password}' | base64 --decode; echo
```

Visit http://localhost:3000 and sign in as `admin` using the retrieved password.

Under **Dashboards**, open:

- **Node Exporter / Nodes** — node CPU, memory, disk, and network.
- **Kubernetes / Compute Resources / Pod** — select namespace `sapp1` or `sapp2` and the corresponding pod.

Prometheus continuously collects metrics inside AKS and stores them on a persistent volume. Port-forwarding only provides temporary browser access.

## Suggested closing summary

> This project separates responsibilities deliberately: Terraform provisions Azure infrastructure and bootstraps Argo CD; Argo CD continuously reconciles platform services and workloads from Git. AKS accesses ACR through managed identity, while ExternalDNS uses OIDC-based Workload Identity to update Azure DNS without a client secret. ingress-nginx and cert-manager complete the public HTTPS delivery path.

## Repository layout

```text
aks/
├── app/                         # Application source and Dockerfiles
│   ├── sapp1/
│   └── sapp2/
├── gitops/
│   ├── apps/                    # Raw workload manifests discovered by ApplicationSet
│   │   ├── sapp1/
│   │   └── sapp2/
│   └── platform/                # Argo CD-managed platform components
│       ├── cert-manager/
│       ├── external-dns/
│       └── ingress-nginx/
└── infra/terraform/
    ├── bootstrap/dev/           # Argo CD bootstrap
    ├── environments/dev/        # Environment composition and state
    └── modules/                 # Reusable Azure infrastructure module
```

## Operational notes

- The environment must be deployed before using this runbook.
- The Namecheap `aks` NS records are a one-time delegation to the name servers returned by Terraform.
- If the Azure DNS Zone is destroyed and recreated, verify its newly assigned name servers before updating the registrar.
- Do not display Kubernetes Secret values during an interview. Workload Identity identifiers are not credentials, but client secrets and tokens must never be printed.
