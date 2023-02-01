param keyVaultName string
param secrets array

resource secret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = [for secret in secrets: {
  name: '${keyVaultName}/${secret.name}'
  properties: {
    value: secret.value
  }
}]
