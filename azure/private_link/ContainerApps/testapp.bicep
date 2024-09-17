param location string
param solutionName string
param environment string

param environmentId string
param userAssignedIdentityId string

param secrets array
param env array

resource containerApp 'Microsoft.App/containerapps@2023-08-01-preview' = {
  name: '${solutionName}-${environment}'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    environmentId: environmentId
    workloadProfileName: 'Consumption'
    configuration: {
      secrets: secrets
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 8080
        // exposedPort: 0
        transport: 'Auto'
        traffic: [
          {
            weight: 100
            latestRevision: true
          }
        ]
        customDomains: [
        ]
        allowInsecure: false
        stickySessions: {
          affinity: 'none'
        }
      }
    }
    template: {
      containers: [
        {
          image: 'dzimchuk/mountpathtest:latest'
          name: '${solutionName}-${environment}'
          env: env
          resources: {
            cpu: '0.5'
            memory: '1Gi'
          }
          probes: []
          volumeMounts: [
            {
              volumeName: 'files'
              mountPath: '/test'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
      volumes: [
        {
          name: 'files'
          storageType: 'AzureFile'
          storageName: 'files'
        }
      ]
    }
  }
}
