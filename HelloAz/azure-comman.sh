# login to azur
az login
az account set --subscription "Azure subscription 1"

# create resouce group 
az group create -n helloaz-rg -l centralus
# or using new line
az group create `
    --name helloaz-rg `
    --location centralus

# CREATE Azure container registry and it needs to be unique globally
ACR_NAME = "helloazacr"
az acr create `
    --resource-group helloaz-rg `
    --name $ACR_NAME `
    --sku Standard

 