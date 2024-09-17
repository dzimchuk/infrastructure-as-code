param location string
param solutionName string
param environment string

param logAnalyticsWorkspaceId string
param virtualNetworkSubnetId string

param fileShareData object

@secure()
param accountKey string

resource appEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: '${solutionName}-${environment}'
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: reference(logAnalyticsWorkspaceId, '2023-09-01').customerId
        sharedKey: listKeys(logAnalyticsWorkspaceId, '2023-09-01').primarySharedKey
      }
    }
    workloadProfiles: [
      {
        workloadProfileType: 'Consumption'
        name: 'Consumption'
      }
    ]
    vnetConfiguration: {
      internal: false
      infrastructureSubnetId: virtualNetworkSubnetId
    }
    // infrastructureResourceGroup: 'ME_${solutionName}_${environment}_${location}'
  }
}

resource fileShare 'Microsoft.App/managedEnvironments/storages@2024-03-01' = {
  parent: appEnvironment
  name: 'files'
  properties: {
    azureFile: {
      accountName: fileShareData.accountName
      accountKey: accountKey
      shareName: fileShareData.shareName
      accessMode: fileShareData.accessMode
    }
  }
}

output environmentId string = appEnvironment.id
