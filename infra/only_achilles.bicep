targetScope = 'resourceGroup'

@description('The location for all resources.')
param location string = resourceGroup().location
param suffix string = 'jw20230815a'

@description('The url of the container where the cdm is stored')
#disable-next-line no-hardcoded-env-urls
param cdmContainerUrl string = 'https://omoppublic.blob.core.windows.net/shared/synthea1k/'

@description('The sas token to access the cdm container')
param cdmSasToken string = ''

@description('The name of the database to create for the OMOP CDM')
param OMOPCDMDatabaseName string = 'synthea1k'

@description('The app service plan sku')
@allowed([
  'S1'
  'S2'
  'S3'
  'B1'
  'B2'
  'B3'
  'P1V2'
  'P2V2'
  'P3V2'
  'P1V3'
  'P2V3'
  'P3V3'
])
param appPlanSkuName string = 'S1'

@description('The postgres sku')
@allowed([
    'Standard_D2s_v3'
    'Standard_D4s_v3'
    'Standard_D8s_v3'
    'Standard_D16s_v3'
    'Standard_D32s_v3'
    'Standard_D48s_v3'
    'Standard_D64s_v3'
    'Standard_D2ds_v4'
    'Standard_D4ds_v4'
    'Standard_D8ds_v4'
    'Standard_D16ds_v4'
    'Standard_D32ds_v4'
    'Standard_D48ds_v4'
    'Standard_D64ds_v4'
    'Standard_D64ds_v4'
    'Standard_B1ms'
    'Standard_B2s'
    'Standard_B2ms'
    'Standard_B4ms'
    'Standard_B8ms'
    'Standard_B12ms'
    'Standard_B16ms'
    'Standard_B20ms'
  ]
)
param postgresSku string = 'Standard_D2s_v3'

@description('The size of the postgres database storage')
@allowed([ 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384 ])
param postgresStorageSize int = 32

@secure()
@description('The password for the postgres admin user')
param postgresAdminPassword string = uniqueString(newGuid())

@secure()
@description('The password for the postgres webapi admin user')
param postgresWebapiAdminPassword string = uniqueString(newGuid())

@secure()
@description('The password for the postgres webapi app user')
param postgresWebapiAppPassword string = uniqueString(newGuid())

@secure()
@description('The password for the OMOP CDM user')
param OMOPCDMPassword string = uniqueString(newGuid())

@secure()
@description('The password for atlas security admin user')
param atlasSecurityAdminPassword string = uniqueString(newGuid())
/*
@secure()
@description('Comma-delimited user list for atlas. Do not use admin as a username. It causes problems with Atlas security')
param atlasUsersList string
*/
@description('Enables local access for debugging.')
param localDebug bool = false

@description('OMOP CDM database type')
@allowed([
    'PostgreSQL'
    'Synapse Dedicated Pool'
  ]
)
param cdmDbType string = 'PostgreSQL'

var tenantId = subscription().tenantId
var vnetName = 'vnet-${suffix}'
var vnetAddressPrefix = '10.0.0.0/16'
var subnetName = 'snet-${suffix}-webapp'
var subnetAddressPrefix = '10.0.0.0/24'

@description('Creates the app service plan')
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' existing = {
  #disable-next-line use-stable-resource-identifiers
  name: 'asp-${suffix}'
}

@description('Creates the key vault')
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  #disable-next-line use-stable-resource-identifiers
  name: 'kv-${suffix}'
}

@description('Creates the integration VNet')
resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' existing = {
  name: vnetName
}
/*
@description('Creates the database server, users and groups required for ohdsi webapi')
module atlasDatabase 'atlas_database.bicep' = {
  name: 'atlasDatabase'
  params: {
    location: location
    suffix: suffix
    keyVaultName: keyVault.name
    postgresSku: postgresSku
    postgresStorageSize: postgresStorageSize
    postgresAdminPassword: postgresAdminPassword
    postgresWebapiAdminPassword: postgresWebapiAdminPassword
    postgresWebapiAppPassword: postgresWebapiAppPassword
    localDebug: localDebug
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.id
    subnetID: vnet.properties.subnets[0].id
  }
}

@description('Creates the ohdsi webapi')
module ohdsiWebApiWebapp 'ohdsi_webapi.bicep' = {
  name: 'ohdsiWebApiWebapp'
  params: {
    location: location
    suffix: suffix
    appServicePlanId: appServicePlan.id
    keyVaultName: keyVault.name
    jdbcConnectionStringWebapiAdmin: 'jdbc:postgresql://${atlasDatabase.outputs.postgresServerFullyQualifiedDomainName}:5432/${atlasDatabase.outputs.postgresWebApiDatabaseName}?user=${atlasDatabase.outputs.postgresWebapiAdminUsername}&password=${postgresWebapiAdminPassword}&sslmode=require'
    postgresWebapiAdminSecret: atlasDatabase.outputs.postgresWebapiAdminSecretName
    postgresWebapiAppSecret: atlasDatabase.outputs.postgresWebapiAppSecretName
    postgresWebapiAdminUsername: atlasDatabase.outputs.postgresWebapiAdminUsername
    postgresWebapiAppUsername: atlasDatabase.outputs.postgresWebapiAppUsername
    postgresWebApiSchemaName: atlasDatabase.outputs.postgresSchemaName
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.id
    subnetID: vnet.properties.subnets[0].id
  }
  dependsOn: [
    atlasDatabase
  ]
}

@description('Creates OMOP CDM database on Postgres')
module omopCDMPostgres 'omop_cdm_postgres.bicep' = if (cdmDbType == 'PostgreSQL') {
  name: 'omopCDMPostgres'
  params: {
    location: location
    keyVaultName: keyVault.name
    cdmContainerUrl: cdmContainerUrl
    cdmSasToken: cdmSasToken
    postgresAtlasDatabaseName: atlasDatabase.outputs.postgresWebApiDatabaseName
    postgresOMOPCDMDatabaseName: OMOPCDMDatabaseName
    postgresAdminPassword: postgresAdminPassword
    postgresWebapiAdminPassword: postgresWebapiAdminPassword
    postgresOMOPCDMPassword: OMOPCDMPassword
    postgresServerName: atlasDatabase.outputs.postgresServerName
    ohdsiWebapiUrl: ohdsiWebApiWebapp.outputs.ohdsiWebapiUrl
    subnetID: vnet.properties.subnets[0].id
  }
  dependsOn: [
    ohdsiWebApiWebapp
    atlasDatabase
  ]
}

@description('Creates OMOP CDM database on Synapse')
module omopCDMSynapse 'omop_cdm_synapse.bicep' = if (cdmDbType == 'Synapse Dedicated Pool') {
  name: 'omopCDMSynapse'
  params: {
    location: location
    suffix: suffix
    keyVaultName: keyVault.name
    cdmContainerUrl: cdmContainerUrl
    cdmSasToken: cdmSasToken    
    databaseName: OMOPCDMDatabaseName
    sqlAdminPassword: OMOPCDMPassword
    ohdsiWebapiUrl: ohdsiWebApiWebapp.outputs.ohdsiWebapiUrl
    subnetID: vnet.properties.subnets[0].id
  }
  dependsOn: [
    ohdsiWebApiWebapp
  ]
}

@description('Creates the ohdsi atlas UI')
module atlasUI 'ohdsi_atlas_ui.bicep' = {
  name: 'atlasUI'
  params: {
    location: location
    suffix: suffix
    appServicePlanId: appServicePlan.id
    ohdsiWebApiUrl: ohdsiWebApiWebapp.outputs.ohdsiWebapiUrl
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.id
    subnetID: vnet.properties.subnets[0].id
  }
  dependsOn: [
    ohdsiWebApiWebapp
  ]
}
*/
//output ohdsiWebapiUrl string = ohdsiWebApiWebapp.outputs.ohdsiWebapiUrl

@description('Creates the ohdsi achilles UI')
module achillesUI 'ohdsi_achilles.bicep' = {
  name: 'achillesUI'
  params: {
    location: location
    suffix: suffix
    appServicePlanId: appServicePlan.id
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.id
    subnetID: vnet.properties.subnets[0].id
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  #disable-next-line use-stable-resource-identifiers
  name: 'log-${suffix}'
}
