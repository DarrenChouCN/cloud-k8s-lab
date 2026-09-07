```bash
cd aks

ACR_NAME=$(terraform -chdir=infra/terraform/environments/dev output -raw acr_name)
ACR_SERVER=$(terraform -chdir=infra/terraform/environments/dev output -raw acr_login_server)
echo $ACR_NAME
echo $ACR_SERVER

az acr login --name "$ACR_NAME"

docker build -t "$ACR_SERVER/sapp1:v1" app/sapp1
docker build -t "$ACR_SERVER/sapp2:v1" app/sapp2

docker push "$ACR_SERVER/sapp1:v1"
docker push "$ACR_SERVER/sapp2:v1"

az acr repository show-tags --name "$ACR_NAME" --repository sapp1 -o table
az acr repository show-tags --name "$ACR_NAME" --repository sapp2 -o table
```