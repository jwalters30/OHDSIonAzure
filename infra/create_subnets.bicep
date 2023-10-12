param vnetName string
param subnetNameApp string
param subnetAddressPrefixApp string
param subnetNameDB string
param subnetAddressPrefixDB string
// var subnetNameSynapse = 'snet-${suffix}-synapse'
// var subnetAddressPrefixSynapse = '10.210.16.96/27'
param subnetNamePE string
param subnetAddressPrefixPE string

@description('Finds the integration VNet')
resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' existing = {
  name: vnetName
  /*
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetNameApp
        properties: {
          addressPrefix: subnetAddressPrefixApp
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: subnetNameDB
        properties: {
          addressPrefix: subnetAddressPrefixDB
          serviceEndpoints: [
            {
              service: 'Microsoft.Sql'
            }
          ]
        }
      }
      {
        name: subnetNameSynapse
        properties: {
          addressPrefix: subnetAddressPrefixSynapse
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Synapse/workspaces'
              }
            }
          ]
        }
      }
      {
        name: subnetNamePE
        properties: {
          addressPrefix: subnetAddressPrefixPE
        }
      }
    ]
  }
  */
}

resource subnetApp 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' = {
  parent: vnet
  name: subnetNameApp
  properties: {
    addressPrefix: subnetAddressPrefixApp
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  /*  networkSecurityGroup: {
      id: networkSecurityGroup.id
    } */
    delegations: [
      {
        name: 'delegation'
        properties: {
          serviceName: 'Microsoft.Web/serverFarms'
        }
      }
    ]
  /*  serviceEndpoints: [
      {
        service: 'Microsoft.Storage'
      }
    ] */
  }
}

resource subnetPE 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' = {
  parent: vnet
  name: subnetNamePE
  properties: {
    addressPrefix: subnetAddressPrefixPE
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Disabled'
  /*  networkSecurityGroup: {
      id: networkSecurityGroup.id
    } */
  /*  delegations: [
      {
        name: 'delegation'
        properties: {
          serviceName: 'Microsoft.Web/serverFarms'
        }
      }
    ] */
  /*  serviceEndpoints: [
      {
        service: 'Microsoft.Storage'
      }
    ] */
  }
}

resource subnetDB 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' = {
  parent: vnet
  name: subnetNameDB
  properties: {
    addressPrefix: subnetAddressPrefixDB
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  /*  networkSecurityGroup: {
      id: networkSecurityGroup.id
    } */
  /*  delegations: [
      {
        name: 'delegation'
        properties: {
          serviceName: 'Microsoft.Web/serverFarms'
        }
      }
    ] */
  /*  serviceEndpoints: [
      {
        service: 'Microsoft.Storage'
      }
    ] */
  }
}

output vnet object = vnet
output subnetDB object = subnetDB
output subnetApp object = subnetApp
