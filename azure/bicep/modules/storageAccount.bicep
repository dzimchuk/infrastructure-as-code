param location string
param storageAccountName string
param environment string
param containerNames array

var storageAccountSkuName = (environment == 'prod') ? 'Standard_RAGRS' : 'Standard_LRS'

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountSkuName
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2022-05-01' = {
  parent: storageAccount
  name: 'default'
}

resource apqp_attachments 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' = [for containerName in containerNames: {
  parent: blobServices
  name: containerName
  properties: {
    immutableStorageWithVersioning: {
      enabled: false
    }
    publicAccess: 'None'
  }
}]
