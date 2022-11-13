# login to azur
az login
az account set --subscription "Azure subscription 1"

$RESOURCE_GROUP_NAME = 'helloaz-rg'
# create resouce group 
az group create -n helloaz-rg -l centralus
# or using new line
az group create `
    --name $RESOURCE_GROUP_NAME `
    --location centralus

# CREATE Azure container registry and it needs to be unique globally
$ACR_NAME = "helloazacr" #variable setup

az acr create `
    --resource-group $RESOURCE_GROUP_NAME `
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


############################Deploying a container in ACI from Private container registry########################################

#Deplo a container from Azure container registry with authentication 
#set some encironment variable and create resoure group for the demo
#You have to use a unique name
$ACR_NAME = "helloazacr" #this is also available on the top

#Obtain the full registry ID and login server which will use in the security and create sections of the demo
$ACR_REGISTRY_ID = $(az acr show --name $ACR_NAME --query id --output tsv)
$ACR_LOGINSERVER = $(az acr show --name $ACR_NAME --query loginServer --output tsv)

#to print
echo $ACR_REGISTRY_ID
echo $ACR_LOGINSERVER

#Now create a service principal and get the password and ID, this will allow azure container instances to pull
$SP_NAME = 'acr-service-principal'


az ad sp list --display-name <Azure resource name>

$SP_PASSWORD = $(az ad sp create-for-rbac `
    --name http://$ACR_NAME-pull `
    --scopes $ACR_REGISTRY_ID `
    --role acrpull `
    --query password `
    --output tsv)

 
#  to get all sp name
az ad sp list --show-mine --query "[].displayName"
#to get details of a specific sp
az ad sp list --display-name http://$ACR_NAME-pull 

#get the id from above query

$SP_APPID  = $(az ad sp show `
    --id edc5b94d-d2a7-4c5f-a3fe-3ddf676b5332 `
    --query appId `
    --output tsv)

#not working
$SP_APPID  = $(az ad sp show `
    --id http://$ACR_NAME-pull `
    --query appId `
    --output tsv)

echo "service pricipal id : $SP_APPID"
echo "service pricipal password : $SP_PASSWORD"

#create the container in aci this will pull our image named 
#$ACR_LOGINSERVER is .... this should match your login server name
$CONTAINER_NAME = 'hello-az-pvt-container-cli'


az container create `
--resource-group $RESOURCE_GROUP_NAME `
--name $CONTAINER_NAME `
--dns-name-label $CONTAINER_NAME `
--port 80 `
--image $ACR_LOGINSERVER/helloazimage:v1 `
--registry-login-server $ACR_LOGINSERVER `
--registry-username $SP_APPID `
--registry-password $SP_PASSWORD


# confirm the container is running and test access to the web app, look in instanceView.state
az container show --resource-group $RESOURCE_GROUP_NAME --name $CONTAINER_NAME


get the url of the container running in aci
this is our hello az app we build in the previous demo
$URL = (az container show --resource-group $RESOURCE_GROUP_NAME --name $CONTAINER_NAME --query ipAddress.fdqn)
echo $URL

http://hello-az-pvt-container-cli.centralus.azurecontainer.io/WeatherForecast

#delete container

az container delete `
--name $CONTAINER_NAME `
--resource-group $RESOURCE_GROUP_NAME `
--yes
