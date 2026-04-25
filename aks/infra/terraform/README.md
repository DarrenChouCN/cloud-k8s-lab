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

terraform -version
terraform -install-autocomplete
```

## 2. Deploy infra
```bash
cd aks/infra/terraform/environments/dev

source ./set-env.sh

terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

## 3. Connect to AKS
```bash
az aks get-credentials \
  --resource-group <resource-group> \
  --name <aks-name>
```