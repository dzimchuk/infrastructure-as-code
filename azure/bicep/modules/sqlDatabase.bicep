param location string
param solutionName string
param environment string

@secure()
@description('Administrator login username for the SQL server.')
param sqlServerAdministratorLogin string

@secure()
@description('Administrator login password for the SQL server.')
param sqlServerAdministratorPassword string

@description('Name and tier of the SQL database SKU.')
param sqlDatabaseSku object

resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: '${solutionName}-${environment}'
  location: location
  properties: {
    administratorLogin: sqlServerAdministratorLogin
    administratorLoginPassword: sqlServerAdministratorPassword
  }
}

resource allowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallRules@2022-05-01-preview' = {
  name: 'AllowAllWindowsAzureIps'
  parent: sqlServer
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  parent: sqlServer
  name: '${solutionName}-${environment}'
  location: location
  sku: {
    name: sqlDatabaseSku.name
    tier: sqlDatabaseSku.tier
  }
}

output sqlDatabaseName string = sqlDatabase.name
