```bash
# Install Ansible
mkdir -p ~/venvs
# .venv path of Ansible for Azure
python3 -m venv ~/venvs/ansible-azure
source ~/venvs/ansible-azure/bin/activate

python -m pip install --upgrade pip
pip install ansible-core
ansible-galaxy collection install azure.azcollection
pip install -r ~/.ansible/collections/ansible_collections/azure/azcollection/requirements.txt

export ANSIBLE_AZURE_AUTH_SOURCE=cli
```

```bash
az provider list --query "[?namespace=='Microsoft.Network'].[namespace,registrationState]" -o table
az provider register --namespace Microsoft.Network --wait

az provider list --query "[?namespace=='Microsoft.Compute'].[namespace,registrationState]" -o table
az provider register --namespace Microsoft.Compute --wait
```

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -C "azure-k8s-lab"

# check ssh key
ls -l ~/.ssh/id_rsa ~/.ssh/id_rsa.pub

chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub


# get VM's public IP
az vm show -d -g rg-wastedetection-dev-aue-01 -n vm-wastedetection-master-aue-01 --query publicIps -o tsv
# login VM
ssh azureuser@<public-ip>
```

# master: ssh azureuser@4.193.84.73
# worker1: ssh azureuser@4.193.190.72
# worker2: ssh azureuser@4.193.212.161

```bash
source ~/venvs/ansible-azure/bin/activate
export AZURE_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
cd ansible
ansible-playbook playbooks/azure_infra.yml
```

```bash
cd ansible
ANSIBLE_ROLES_PATH=./roles ansible-playbook -i inventory/localhost.yml playbooks/k8s_cluster.yml
```

```bash
scp ansible/deployment/deployment.yaml azureuser@104.215.191.120:~/
scp ansible/deployment/service.yaml azureuser@104.215.191.120:~/

kubectl scale deployment yolo-waste-api --replicas=1
kubectl scale deployment yolo-waste-api --replicas=2
kubectl scale deployment yolo-waste-api --replicas=4
kubectl scale deployment yolo-waste-api --replicas=8
```