param suffix string = 'sbmri'
var tenantId = 'eafa1b31-b194-425d-b366-56c215b7760c'

@description('Creates the key vault')
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  #disable-next-line use-stable-resource-identifiers
  name: 'kv-${suffix}'
}


resource ohdsiWebapiAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = {
  name: 'add'
  parent: keyVault
  properties: {
    accessPolicies: [
      {
        objectId: '7f83d432-bf4a-4d15-b972-4871bd8b9225'
        permissions: {
          secrets: [
            'Get'
            'List'
            'Set'
            'Delete'
          ]
        }
        tenantId: tenantId
      }
    ]
  }
}
