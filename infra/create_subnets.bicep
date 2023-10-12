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
