# How to host KeyCloak on Azure Web App for containers

In some of my recent project we had to use KeyCloak instead of Azure Active Directory as IdP. For production there were already some KeyCloak instances avaialbe but not for our developmnet envirocnment. Because of that we were looking for a easy to host, easy to maintain and also cheep solution to host KeyCloak by ourself.

As there is a docker image available for KeyCloak we decided to go for it and wanted to host this on a Azure Web App for Containers. Can host a container image, provdes https out of the box and is a quiete cheep service compered to an AKS cluster.


## Setup KeyCloak

Setting up a Web App for Containers and run KeyCloak on it is quite simple:

```powershell
$location = 'westeurope'
$rgName = 'rg-keycloak'
$appServicePlan = 'keycloakplan'
$webApp = 'keycloakOnAzure'
$subscription = ''
$keyCloakAdminUser = '' 
$keyCloakAdminPassword = '' 

az group create --location $location --name $rgName --subscription $subscription

az appservice plan create -g $rgName --name $appServicePlan --is-linux --sku P2V2
az webapp create -g $rgName -p $appServicePlan -n $webApp -i jboss/keycloak:latest
az webapp config appsettings set -g $rgName -n $webApp --settings KEYCLOAK_PASSWORD=$keyCloakAdminPassword
az webapp config appsettings set -g $rgName -n $webApp --settings KEYCLOAK_USER=$keyCloakAdminUser
az webapp config appsettings set -g $rgName -n $webApp --settings WEBSITES_PORT=8080
az webapp config appsettings set -g $rgName -n $webApp --settings PROXY_ADDRESS_FORWARDING=true
```

### Impoortant lines:

```powershell
az webapp config appsettings set -g $rgName -n $webApp --settings WEBSITES_PORT=8080
```

>The container image hosts the webpage on port 8080. The WEBSITES_PORT app setting lets the app service know tho which port of the container the requests needed to be forwarded.

```powershell
az webapp config appsettings set -g $rgName -n $webApp --settings PROXY_ADDRESS_FORWARDING=true
```

>This line changes the routing behavior of the web app. We need to enable it so that the app in the container can handle the adresses.

## Add persistence
The code above was all that is needed to setup KeyCloak. The KeyCloak image brings its own DB to store the settings, sounds good for the moment but a restart of the Web App will also reinitiate the container. Therefore a DB connection needs to be configured to store the data.

This can be done with the following code:

```powershell
$postgreServerName = ''
$postgreSQLUserName =''
$postgreSQLPW = ''
$dbName = 'iam'

az postgres flexible-server create --resource-group $rgName --name $postgreServerName --admin-password $postgreSQLPW --admin-user $postgreSQLUserName --database-name $dbName --public-access 0.0.0.0
$postgresServer = az postgres flexible-server list --resource-group $rgName | ConvertFrom-Json
$fqdn = $postgresServer[0].fullyQualifiedDomainName
az webapp config appsettings set -g $rgName -n $webApp --settings DB_ADDR=$fqdn
az webapp config appsettings set -g $rgName -n $webApp --settings DB_DATABASE=$dbName
az webapp config appsettings set -g $rgName -n $webApp --settings DB_PASSWORD=$postgreSQLPW
az webapp config appsettings set -g $rgName -n $webApp --settings DB_USER=$postgreSQLUserName
az webapp config appsettings set -g $rgName -n $webApp --settings DB_VENDOR=postgres
```

```powershell
az postgres flexible-server create ... --public-access 0.0.0.0
```
>The public-access 0.0.0.0 enables the `Allow public access from any Azure service within Azure to this server` setting. Without this KeyCloak would not be able to connect to the database.


Congrats you can now restart the Web App as often as you want without losing your data.
