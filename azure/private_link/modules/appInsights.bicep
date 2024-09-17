param location string
param solutionName string
param environment string

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: '${solutionName}-${environment}'
  location: location
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${solutionName}-${environment}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspace.id
  }
}

output appInsights object = appInsights
output logAnalytics object = workspace
