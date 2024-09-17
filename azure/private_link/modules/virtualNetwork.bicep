param location string
param solutionName string
param environment string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-06-01' = {
  name: '${solutionName}-${environment}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    encryption: {
      enabled: false
      enforcement: 'AllowUnencrypted'
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.0.0/24'
          serviceEndpoints: [
            {
              service: 'Microsoft.Sql'
              locations: [
                location
              ]
            }
            {
              service: 'Microsoft.KeyVault'
              locations: [
                '*'
              ]
            }
            {
              service: 'Microsoft.Storage'
              locations: [
                location
              ]
            }
          ]
          delegations: [
            // {
            //   name: 'Microsoft.Web.serverFarms'
            //   properties: {
            //     serviceName: 'Microsoft.Web/serverFarms'
            //   }
            //   type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
            // }
            {
              name: 'Microsoft.App.environments'
              properties: {
                serviceName: 'Microsoft.App/environments'
              }
              type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
            }
          ]
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          defaultOutboundAccess: true
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
    ]
  }
}

output virtualNetworkId string = virtualNetwork.id
output defaultSubnetId string = virtualNetwork.properties.subnets[0].id
