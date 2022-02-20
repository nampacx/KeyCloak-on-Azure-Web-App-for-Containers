$location = ''
$rgName = ''
$appServicePlan = ''
$webApp = ''
$subscription = ''

$postgreServerName = ''
$postgreSQLUserName =''
$postgreSQLPW = ''
$dbName = 'iam'

$keyCloakAdminUser = ''
$keyCloakAdminPassword = ''

az login
az account set -s $subscription
az group create --location $location --name $rgName --subscription $subscription

az appservice plan create -g $rgName --name $appServicePlan --is-linux --sku P2V2
az webapp create -g $rgName -p $appServicePlan -n $webApp -i jboss/keycloak:latest
az webapp config appsettings set -g $rgName -n $webApp --settings KEYCLOAK_PASSWORD=$keyCloakAdminPassword
az webapp config appsettings set -g $rgName -n $webApp --settings KEYCLOAK_USER=$keyCloakAdminUser
az webapp config appsettings set -g $rgName -n $webApp --settings PROXY_ADDRESS_FORWARDING=true
az webapp config appsettings set -g $rgName -n $webApp --settings WEBSITES_PORT=8080

az postgres flexible-server create --resource-group $rgName --name $postgreServerName --admin-password $postgreSQLPW --admin-user $postgreSQLUserName --database-name $dbName --public-access 0.0.0.0
$postgresServer = az postgres flexible-server list --resource-group $rgName | ConvertFrom-Json
$fqdn = $postgresServer[0].fullyQualifiedDomainName
az webapp config appsettings set -g $rgName -n $webApp --settings DB_ADDR=$fqdn
az webapp config appsettings set -g $rgName -n $webApp --settings DB_DATABASE=$dbName
az webapp config appsettings set -g $rgName -n $webApp --settings DB_PASSWORD=$postgreSQLPW
az webapp config appsettings set -g $rgName -n $webApp --settings DB_USER=$postgreSQLUserName
az webapp config appsettings set -g $rgName -n $webApp --settings DB_VENDOR=postgres