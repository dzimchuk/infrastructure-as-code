param keyVaultName string
param secretName string

@secure()
param secretValue string

param contentType string = ''

resource secret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: '${keyVaultName}/${secretName}'
  properties: {
    value: secretValue
    contentType: contentType
  }
}
