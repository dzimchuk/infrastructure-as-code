param location string = resourceGroup().location
param solutionName string = 'testapp'

@minValue(1)
@maxValue(10)
param appServicePlanInstanceCount int = 1

@allowed([
  'dev'
  'prod'
])
param environment string

@secure()
@description('Administrator login username for the SQL server.')
param sqlServerAdministratorLogin string

@secure()
@description('Administrator login password for the SQL server.')
param sqlServerAdministratorPassword string

@secure()
@description('Application login username for the SQL server.')
param sqlServerLogin string

@secure()
@description('Application login password for the SQL server.')
param sqlServerPassword string

@description('Name and tier of the SQL database SKU.')
param sqlDatabaseSku object

param configureCustomDomain bool = true

@description('Custom domain name settings')
param customDomainSettings object

module appInsights 'modules/appInsights.bicep' = {
  name: '${solutionName}-appinsights-${environment}'
  params: {
    location: location
    solutionName: solutionName
    environment: environment
  }
}

var storageAccountName = '${solutionName}storage${environment}'
var attachmentsContainerName = 'apqp-attachments'
module storageAccount 'modules/storageAccount.bicep' = {
  name: '${solutionName}-storage-${environment}'
  params: {
    location: location
    storageAccountName: storageAccountName
    environment: environment
    containerNames: [attachmentsContainerName]
  }
}

module sqlDatabase 'modules/sqlDatabase.bicep' = {
  name: '${solutionName}-sql-${environment}'
  params: {
    location: location
    solutionName: solutionName
    environment: environment
    sqlServerAdministratorLogin: sqlServerAdministratorLogin
    sqlServerAdministratorPassword: sqlServerAdministratorPassword
    sqlDatabaseSku: sqlDatabaseSku
  }
}

module emailTrigger 'modules/logicApp.bicep' = {
  name: '${solutionName}-email-${environment}'
  params: {
    location: location
    solutionName: solutionName
    environment: environment
    url: '${appService.outputs.urls.api}/api/Scheduler/ProcessEmail'
  }
}

module keyVault 'modules/keyVault.bicep' = {
  name: '${solutionName}-keyvault-${environment}'
  params: {
    location: location
    solutionName: solutionName
    environment: environment
  }
}

resource storageAccountRef 'Microsoft.Storage/storageAccounts@2022-05-01' existing = {
  name: storageAccountName
}

var kvStorageAccountKey = 'StorageAccountKey'
var kvStorageConnectionStrng = 'StorageConnectionString'
var kvSqlConnectionString = 'SqlConnectionStrings'

module keyVaultSecrets 'modules/keyVaultSecrets.bicep' = {
  name: '${solutionName}-secrets-${environment}'
  dependsOn: [
    keyVault
  ]
  params: {
    keyVaultName: keyVault.outputs.keyVaultName
    secrets: [
      {
        name: kvStorageAccountKey
        value: listKeys(storageAccountRef.id, storageAccountRef.apiVersion).keys[0].value
      }
      {
        name: kvStorageConnectionStrng
        value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountRef.name};AccountKey=${listKeys(storageAccountRef.id, storageAccountRef.apiVersion).keys[0].value};EndpointSuffix=${az.environment().suffixes.storage}'
      }
      {
        name: kvSqlConnectionString
        value: 'Server=tcp:${sqlDatabase.outputs.sqlDatabaseName}${az.environment().suffixes.sqlServerHostname},1433;Initial Catalog=${sqlDatabase.outputs.sqlDatabaseName};Persist Security Info=False;User ID=${sqlServerLogin};Password=${sqlServerPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
      }
    ]
  }
}

module appService 'modules/appService.bicep' = {
  name: '${solutionName}-appservice-${environment}'
  params: {
    location: location
    solutionName: solutionName
    environment: environment
    appServicePlanInstanceCount: appServicePlanInstanceCount
    apiAppSettings: [
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: appInsights.outputs.appInsights.properties.ConnectionString
      }
      {
        name: 'AppSettings:BlobStorage:AccountKey'
        value: format('@Microsoft.KeyVault(VaultName={0};SecretName={1})', keyVault.outputs.keyVaultName, kvStorageAccountKey)
      }
      {
        name: 'AppSettings:StorageConnectionString'
        value: format('@Microsoft.KeyVault(VaultName={0};SecretName={1})', keyVault.outputs.keyVaultName, kvStorageConnectionStrng)
      }
      {
        name: 'ConnectionStrings:DefaultConnection'
        value: format('@Microsoft.KeyVault(VaultName={0};SecretName={1})', keyVault.outputs.keyVaultName, kvSqlConnectionString)
      }
      {
        name: 'AppSettings:BlobStorage:AccountName'
        value: storageAccountRef.name
      }
      {
        name: 'AppSettings:BlobStorage:ContainerName'
        value: attachmentsContainerName
      }
      {
        name: 'Test'
        value: 'test value'
      }
    ]
  }
}

module keyVaultAccessPolicy 'modules/keyVaultAccessPolicy.bicep' = {
  name: '${solutionName}-keyvaultpolicy-${environment}'
  dependsOn: [
    keyVault
  ]
  params: {
    keyVaultName: keyVault.outputs.keyVaultName
    principalIds: [appService.outputs.principalIds.api]
  }
}

module apiCustomHostName 'modules/customDomain.bicep' = if(configureCustomDomain) {
  name: 'ApiCustomHostname'
  params: {
    appName: appService.outputs.appNames.api
    dnsZone: customDomainSettings.dnsZone
    appCustomHostname: customDomainSettings.apiCustomHostname
    location: location
    hostingPlanId: appService.outputs.hostingPlan.id
  }
}

module appCustomHostName 'modules/customDomain.bicep' = if(configureCustomDomain) {
  name: 'AppCustomHostname'
  params: {
    appName: appService.outputs.appNames.app
    dnsZone: customDomainSettings.dnsZone
    appCustomHostname: customDomainSettings.appCustomHostname
    location: location
    hostingPlanId: appService.outputs.hostingPlan.id
  }
}
