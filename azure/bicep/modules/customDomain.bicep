// see https://github.com/Azure/bicep/blob/main/src/Bicep.Core.Samples/Files/user_submitted/301/function-app-with-custom-domain-managed-certificate/main.bicep
//
// Enabling Managed certificate for a webapp requires 3 steps
// 1. Add custom domain to webapp with SSL in disabled state
// 2. Generate certificate for the domain
// 3. enable SSL
//
// The last step requires deploying again Microsoft.Web/sites/hostNameBindings - and ARM template forbids this in one deplyment, therefore we need to use modules to chain this.

param appName string
param appCustomHostname string
param location string
param hostingPlanId string

@description('Existing Azure DNS zone in target resource group')
param dnsZone string

// resource dnsTxt 'Microsoft.Network/dnsZones/TXT@2018-05-01' = {
//   name: '${dnsZone}/asuid.${appCustomHostname}'
//   properties: {
//     TTL: 3600
//     TXTRecords: [
//       {
//         value: [
//           '${functionApp.properties.customDomainVerificationId}'
//         ]
//       }
//     ]
//   }
// }

// resource dnsCname 'Microsoft.Network/dnsZones/CNAME@2018-05-01' = {
//   name: '${dnsZone}/${appCustomHostname}'
//   properties: {
//     TTL: 3600
//     CNAMERecord: {
//       cname: '${functionApp.name}.azurewebsites.net'
//     }
//   }
// }

resource appCustomHost 'Microsoft.Web/sites/hostNameBindings@2022-03-01' = {
  name: '${appName}/${appCustomHostname}.${dnsZone}'
  // dependsOn: [
  //   dnsTxt
  //   dnsCname
  // ]
  properties: {
    hostNameType: 'Verified'
    sslState: 'Disabled'
    customHostNameDnsRecordType: 'CName'
    siteName: appName
  }
}

resource appCustomHostCertificate 'Microsoft.Web/certificates@2022-03-01' = {
  name: '${appCustomHostname}.${dnsZone}'
  location: location
  dependsOn: [
    appCustomHost
  ]
  properties: any({
    serverFarmId: hostingPlanId
    canonicalName: '${appCustomHostname}.${dnsZone}'
  })
}

// we need to use a module to enable sni, as ARM forbids using resource with this same type-name combination twice in one deployment.
module appCustomHostEnable './sniEnable.bicep' = {
  name: '${appCustomHostname}-sni-enable'
  params: {
    appName: appName
    appHostname: appCustomHostCertificate.name
    certificateThumbprint: appCustomHostCertificate.properties.thumbprint
  }
}
