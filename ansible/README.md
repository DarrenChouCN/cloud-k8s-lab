## 1. Prepare Ansible in Ubuntu WSL

```bash
# create a Python virtual environment for Ansible
mkdir -p ~/venvs
python3 -m venv ~/venvs/ansible-azure
source ~/venvs/ansible-azure/bin/activate

# install Ansible and Azure collection
python -m pip install --upgrade pip
pip install ansible-core
ansible-galaxy collection install azure.azcollection
pip install -r ~/.ansible/collections/ansible_collections/azure/azcollection/requirements.txt

# use Azure CLI authentication
export ANSIBLE_AZURE_AUTH_SOURCE=cli
```

## 2. Register Required Azure Resource Providers
```bash
az provider list --query "[?namespace=='Microsoft.Network'].[namespace,registrationState]" -o table
az provider register --namespace Microsoft.Network --wait

az provider list --query "[?namespace=='Microsoft.Compute'].[namespace,registrationState]" -o table
az provider register --namespace Microsoft.Compute --wait
```

## 3. Prepare SSH Access
```bash
# create SSH key pair
mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -C "azure-k8s-lab"

# check SSH key files
ls -l ~/.ssh/id_rsa ~/.ssh/id_rsa.pub

chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub


# To get the public IP of a VM and connect to it
az vm show -d -g rg-wastedetection-dev-aue-01 -n vm-wastedetection-master-aue-01 --query publicIps -o tsv
ssh azureuser@<public-ip>
```

## 4. Deploy Azure Infrastructure with Ansible
```bash
source ~/venvs/ansible-azure/bin/activate
export AZURE_SUBSCRIPTION_ID=$(az account show --query id -o tsv)

cd ansible
ansible-playbook playbooks/azure_infra.yml
```

## 5. Deploy the Kubernetes Cluster with Ansible
```bash
cd ansible
ANSIBLE_ROLES_PATH=./roles ansible-playbook -i inventory/localhost.yml playbooks/k8s_cluster.yml
```

## 6. Build the Docker Image Locally
```bash
# start Docker service
sudo service docker start
sudo usermod -aG docker $USER
newgrp docker
docker version

# build the application image
docker build -t yolo-waste-api:v1 .
docker images
```

## 7. Push the Docker Image to Azure Container Registry
```bash
ACR_NAME=<acr_name>
LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer --output tsv)

az acr login --name $ACR_NAME
docker tag yolo-waste-api:v2 $LOGIN_SERVER/yolo-waste-api:v2
docker push $LOGIN_SERVER/yolo-waste-api:v2

az acr repository show-tags --name $ACR_NAME --repository yolo-waste-api --output table
```

## 8. Create ACR Pull Secret in Kubernetes
```bash
# enable admin access for ACR
az acr update -n acrwastedetectionsea01 --admin-enabled true

# get ACR credentials
az acr credential show -n acrwastedetectionsea01

# Then create the pull secret on the Kubernetes master node
kubectl create secret docker-registry acr-auth \
  --docker-server=acrwastedetectionsea01.azurecr.io \
  --docker-username='<ACR_USERNAME>' \
  --docker-password='<ACR_PASSWORD>'

# Verify the secret
kubectl get secret acr-auth
```

## 9. Deploy the Application to Kubernetes
```bash
# Copy the Kubernetes YAML files to the master node:
# 4.193.254.153
scp ansible/deployment/deployment.yaml azureuser@<master-node-ip>:~/
scp ansible/deployment/service.yaml azureuser@<master-node-ip>:~/

scp ansible/deployment/deployment.yaml azureuser@4.193.254.153:~/
scp ansible/deployment/service.yaml azureuser@4.193.254.153:~/

# Then apply them on the master node
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

## 10. Scale the Application for Testing
```bash
kubectl scale deployment yolo-waste-api --replicas=1
kubectl scale deployment yolo-waste-api --replicas=2
kubectl scale deployment yolo-waste-api --replicas=4
kubectl scale deployment yolo-waste-api --replicas=8
```