param appName string
param appHostname string
param certificateThumbprint string

resource hostNameBinding 'Microsoft.Web/sites/hostNameBindings@2022-03-01' = {
  name: '${appName}/${appHostname}'
  properties: {
    sslState: 'SniEnabled'
    thumbprint: certificateThumbprint
  }
}
