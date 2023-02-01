param keyVaultName string
param principalIds array

var tenantId = subscription().tenantId

resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = {
  name: '${keyVaultName}/add'
  properties: {
    accessPolicies: [for principalId in principalIds: {
        tenantId: tenantId
        objectId: principalId
        permissions: {
          secrets: [
            'get'
          ]
        }
      }]
  }
}

