param location string
param keyVaultName string

param virtualNetworkSubnetId string

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    tenantId: subscription().tenantId
    accessPolicies: []
    sku: {
      name: 'standard'
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: virtualNetworkSubnetId
          ignoreMissingVnetServiceEndpoint: false
        }
      ]
    }
  }
}

output keyVaultName string = keyVault.name
