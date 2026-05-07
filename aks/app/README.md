```bash
cd app/sapp1

docker build -t sapp1:v1 .

docker tag sapp1:v1 <your-acr>.azurecr.io/sapp1:v1
# docker tag sapp2:v1 acrcloudk8slabdevause01.azurecr.io/sapp2:v1

az acr login --name <your-acr-name>
# az acr login --name acrcloudk8slabdevause01

docker push <your-acr>.azurecr.io/sapp1:v1
# docker push acrcloudk8slabdevause01.azurecr.io/sapp2:v1

docker rmi <local-image>
# docker rmi sapp1:v1
```