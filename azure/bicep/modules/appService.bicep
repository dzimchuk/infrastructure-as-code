param location string
param solutionName string
param environment string
param appServicePlanInstanceCount int
param apiAppSettings array

var appServicePlanSkuName = (environment == 'prod') ? 'P2v2' : 'S2'

var defaultAppSettings = [
  {
    name: 'WEBSITE_RUN_FROM_PACKAGE'
    value: '1'
  }
]

resource appServicePlan 'Microsoft.Web/serverFarms@2021-03-01' = {
  name: '${solutionName}-${environment}-sp'
  location: location
  sku: {
    name: appServicePlanSkuName
    capacity: appServicePlanInstanceCount
  }
}

resource appServiceApi 'Microsoft.Web/sites@2022-03-01' = {
  name: '${solutionName}-${environment}-api'
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource apiConfig 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'web'
  parent: appServiceApi
  properties: {
    metadata: [
      {
        name: 'CURRENT_STACK'
        value: 'dotnet'
      }
    ]
    alwaysOn: true
    netFrameworkVersion: 'v6.0'
    appSettings: concat(defaultAppSettings, apiAppSettings)
  }
}

resource appServiceFrontend 'Microsoft.Web/sites@2022-03-01' = {
  name: '${solutionName}-${environment}-app'
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
  }
}

resource frontendConfig 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'web'
  parent: appServiceFrontend
  properties: {
    metadata: [
      {
        name: 'CURRENT_STACK'
        value: 'node'
      }
    ]
    alwaysOn: true
    nodeVersion: '~12'
    appSettings: concat(defaultAppSettings, [
      {
        name: 'WEBSITE_NODE_DEFAULT_VERSION'
        value: '12.13.0'
      }
    ])
  }
}

output urls object = {
  api: 'https://${appServiceApi.properties.defaultHostName}'
  app: 'https://${appServiceFrontend.properties.defaultHostName}'
}

output principalIds object = {
  api: appServiceApi.identity.principalId
}

output hostingPlan object = {
  id: appServicePlan.id
}

output appNames object = {
  api: appServiceApi.name
  app: appServiceFrontend.name
}
