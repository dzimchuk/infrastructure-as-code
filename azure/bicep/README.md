# Introduction 
This repository contains [Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview?tabs=bicep) templates for managing Meshworks infrastructure.

# Prerequisites
- Azure CLI or Powershell modules
- Install Bicep modules `az bicep install`
- Add SQL credentails to `Dzimchuk-TestKeyVault` (see below)
- Add DNS records for custom domain names (see below)

There are extensions available for VS Code and Visual Studio that make working with Bicep files convenient.

# Running deployments

Azure CLI and Powershell commands that apply ARM templates work seamlessly with Bicep files translating them to ARM templates before sending to Azure.

By default ARM deployments are incremental.

```
az deployment group create -g <resource group name> --template-file testapp.bicep --parameters testapp.parameters.<env>.json
```

Note: if DNS records for custom domain names have not been configured yet you can skip their configuration in App Services:

```
az deployment group create -g <resource group name> \
--template-file testapp.bicep \
--parameters testapp.parameters.<env>.json \
configureCustomDomain=false
```

Restart API app to make sure KeyVault references get resolved:
```
az webapp restart -n <app name> -g <resource group name>
```

# SQL credentials

A KeyVault named `Dzimchuk-TestKeyVault` (resource group: TestKeyVault) contains SQL credentials for different environments. For example, for a new Prod instance there are the following keys:

- TestApp-SqlAdminLogin-Prod
- TestApp-SqlAdminPwd-Prod
- TestApp-SqlLogin-Prod
- TestApp-SqlPwd-Prod

These credentials must be defined in `Dzimchuk-TestKeyVault` prior to running deployment as they are read automatically by ARM.

## App credentials

It is recommended that applications use application level credentials to access SQL databases that are scoped to specific databases.

To set up new application login connect to SQL Server instance with SQL Server Management Studio using admin credentials.

Right-click the `master` database and select `New Query`. Run the following command to add a new login:

```
CREATE LOGIN appconn WITH password='<new password>';
```

Right-click the application database (e.g. `testapp-prod`) and select `New Query`. Run the following commands to add a new user to the database and assign it to `db_owner` role:

```
CREATE USER appconn FROM LOGIN appconn;
EXEC sp_addrolemember 'db_owner', appconn;
```

Persist application credentials in `Dzimchuk-TestKeyVault` (resource group: TestKeyVault) as secrets, e.g.:

- TestApp-SqlLogin-Prod (appconn)
- TestApp-SqlPwd-Prod (newly generated password)

When connecting to the database using application credentials make sure to set `Initial Catalog` parameter in the connection string to the application database (e.g. `testapp-prod`).

## DNS records for custom domain names

We configure custom domain names for both frontend and API apps but before we can run those configuration we need to insure CNAME and TXT verification records are present in dzimchuk.com domain.

Example for Prod environment:

```
CNAME:
prod -> testapp-prod-app.azurewebsites.net
prod-api -> testapp-prod-api.azurewebsites.net

TXT:
asuid.prod -> AD2545F9DFFCCFD90C4D6E3C477A090BCE4B904BA7DB27FD984E6BBAE6AC6017
asuid.prod-api -> AD2545F9DFFCCFD90C4D6E3C477A090BCE4B904BA7DB27FD984E6BBAE6AC6017
```

Value that should be set for verification records is Service Plan specific and it can be obtained on the portal.

We also configure automatic App Service certificates.
