$RESOURCE_GROUP_NAME = 'webapps-rg'

az group create -n $RESOURCE_GROUP_NAME -l CentralUS

az group delete --resource-group $RESOURCE_GROUP_NAME
# Delete a resource group.

az group list --query "[?location=='westus2']"

#create a plan
$APP_SERVICE_PLAN_NAME = 'webapps-dev-plan'

az appservice plan create --name $APP_SERVICE_PLAN_NAME `
--resource-group $RESOURCE_GROUP_NAME `
--sku FREE `
--is-linux

# create web app
$WEB_APP_NAME = 'dalim3281'

az webapp create -g $RESOURCE_GROUP_NAME `
-p $APP_SERVICE_PLAN_NAME `
-n $WEB_APP_NAME `
--runtime "DOTNETCORE:6.0"

#check list
az webapp list-runtimes --linux


