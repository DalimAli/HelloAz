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
$ACR_NAME = "helloazacr" #variable setup

az acr create `
    --resource-group helloaz-rg `
    --name $ACR_NAME `
    --sku Standard

#  log into acr to push containers
az acr login --name $ACR_NAME


# get the login server which is used in the image tag
$ACR_LOGGINSERVER = $(az acr show --name $ACR_NAME --query loginServer --output tsv)
echo $ACR_LOGGINSERVER

#set image name
$DOCKER_IMAGE = "helloazimage"
# CREATE --Tag the container image using the login server name. This doesnt push it to acr, the next step
#[loginUrl]/[repository:][tag]

docker tag helloazimage:v1 $ACR_LOGGINSERVER/helloazimage:v1
docker image ls $ACR_LOGGINSERVER/helloazimage:v1
docker image ls

#Push image to Azure container registry
docker push $ACR_LOGGINSERVER/helloazimage:v1

#get the list of the repositories and images/tags in our acr
az acr repository list --name $ACR_NAME --output table
az acr repository show-tags --name $ACR_NAME --repository helloazimage --output table

#using acr task to build and push a container image
az acr build --image "helloazimage:v1-acr-task" --registry $ACR_NAME .

#Both images are in there now, the one we built locally and the one build with acr task
az acr repository show-tags --name $ACR_NAME --repository helloazimage --output table


#deploying acr using cli using a public registry
#its a public registry image not your

az container create `
    --resource-group helloaz-rg `
    --name helloaz-container-cli `
    --dns-name-label helloaz-container-cli `
    --image mcr.microsoft.com/azuredocs/aci-helloworld `
    --ports 80

#check stauts of the container info
az container show --resource-group 'helloaz-rg' --name 'helloaz-container-cli'


#retrive the url , the format is [name].[region].azurecontainer.io
$URL=$(az container show --resource-group 'helloaz-rg' --name 'helloaz-container-cli' --query ipAddress.fqdn)
