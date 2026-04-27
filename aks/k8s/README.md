## 1. Install kubectl

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /' \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubectl

kubectl version --client
```

## 2. Install Helm
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

helm version
```

## 3. Deploy Nginx app
```bash
kubectl apply -f aks/k8s/sapp1/
kubectl get pods
kubectl get svc

kubectl apply -f aks/k8s/sapp1/ingress.yaml
curl -H "Host: sapp1.darrencloudlab.com" http://<INGRESS_PUBLIC_IP>
# curl -H "Host: sapp1.darrencloudlab.com" http://20.70.70.50
```