param location string
param solutionName string
param environment string
param url string

resource emailTrigger 'Microsoft.Logic/workflows@2017-07-01' = {
  name: '${solutionName}-${environment}-ProcessEmail'
  location: location
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
      }
      triggers: {
        Recurrence: {
          recurrence: {
            frequency: 'Minute'
            interval: 10
          }
          evaluatedRecurrence: {
            frequency: 'Minute'
            interval: 10
          }
          type: 'Recurrence'
        }
      }
      actions: {
        HTTP: {
          runAfter: {
          }
          type: 'Http'
          inputs: {
            method: 'GET'
            uri: url
          }
        }
      }
      outputs: {
      }
    }
    parameters: {
    }
  }
}
