param solutionName string = 'testenv'

param storageAccountSku string = 'Standard_LRS'

@allowed([
  'test'
])
param environment string

@description('CORS configuration for a given environment.')
param CORS object

// Subscription scope is required to create a resource group
// targetScope = 'subscription'

// resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
//   name: '${solutionName}-${environment}'
//   location: location
// }

var rg = resourceGroup()
var location = rg.location

module appInsights 'modules/appInsights.bicep' = {
  name: '${solutionName}-${environment}-appinsights'
  scope: rg
  params: {
    location: location
    solutionName: solutionName
    environment: environment
  }
}

var suffix = uniqueString('${environment}-${resourceGroup().id}')
var globallyUniqueName = '${solutionName}-${suffix}'
var storageAccountName = '${solutionName}${suffix}'

var fileShareName = 'testshare'

module virtualNetwork 'modules/virtualNetwork.bicep' = {
  name: '${solutionName}-${environment}-vnet'
  scope: rg
  params: {
    location: location
    solutionName: solutionName
    environment: environment
  }
}

module storageAccount 'modules/storageAccount.bicep' = {
  name: '${solutionName}-${environment}-storage'
  scope: rg
  params: {
    location: location
    storageAccountName: storageAccountName
    storageAccountSku: storageAccountSku
    containerNames: []
    queueNames: []
    fileShareNames: [ fileShareName ]
    CORS: CORS
    keyVaultName: keyVault.outputs.keyVaultName
    virtualNetworkSubnetId: virtualNetwork.outputs.defaultSubnetId
  }
}

module keyVault 'modules/keyVault.bicep' = {
  name: '${solutionName}-${environment}-keyvault'
  scope: rg
  params: {
    location: location
    keyVaultName: globallyUniqueName
    virtualNetworkSubnetId: virtualNetwork.outputs.defaultSubnetId
  }
}

resource secretAccessIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${solutionName}-${environment}'
  location: location
}

module keyVaultAccessPolicy 'modules/keyVaultAccessPolicy.bicep' = {
  name: '${solutionName}-${environment}-keyvaultpolicy'
  scope: rg
  dependsOn: [
    keyVault
  ]
  params: {
    keyVaultName: keyVault.outputs.keyVaultName
    principalIds: [ secretAccessIdentity.properties.principalId ]
  }
}

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVault.outputs.keyVaultName
  scope: rg
}

var fileShareData = {
  accountName: storageAccount.outputs.name
  shareName: fileShareName
  accessMode: 'ReadWrite'
}

module containerAppsEnvironment 'modules/containerAppsEnvironment.bicep' = {
  name: '${solutionName}-${environment}-containerAppsEnv'
  params: {
    location: location
    solutionName: solutionName
    environment: environment
    logAnalyticsWorkspaceId: appInsights.outputs.logAnalytics.resourceId
    virtualNetworkSubnetId: virtualNetwork.outputs.defaultSubnetId
    fileShareData: fileShareData
    accountKey: kv.getSecret(storageAccount.outputs.accountKeySecretName)
  }
}

var urlPrefix = 'https://${keyVault.outputs.keyVaultName}${az.environment().suffixes.keyvaultDns}/secrets'

// module containerApp 'ContainerApps/testapp.bicep' = {
//   name: '${solutionName}-${environment}-containerApp'
//   params: {
//     location: location
//     solutionName: solutionName
//     environment: environment
//     environmentId: containerAppsEnvironment.outputs.environmentId
//     userAssignedIdentityId: secretAccessIdentity.id
//     secrets: [
//       {
//         name: 'appInsights-conn-string'
//         value: appInsights.outputs.appInsights.properties.ConnectionString
//       }
//       {
//         name: 'storage-conn-string'
//         keyVaultUrl: '${urlPrefix}/${storageAccount.outputs.connectionStringSecretName}'
//         identity: secretAccessIdentity.id
//       }
//     ]
//     env: [
//       {
//         name: 'ApplicationInsights__ConnectionString'
//         secretRef: 'appInsights-conn-string'
//       }
//       {
//         name: 'ConnectionStrings__Storage'
//         secretRef: 'storage-conn-string'
//       }
//       {
//         name: 'WorkingDirectory'
//         value: '/test'
//       }
//     ]
//   }
// }
