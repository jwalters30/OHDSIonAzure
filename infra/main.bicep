targetScope = 'resourceGroup'

@description('The location for all resources.')
param location string = resourceGroup().location
param suffix string = 'jw20231012'

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
param postgresSku string = 'Standard_D2ds_v4'

@description('The size of the postgres database storage')
@allowed([ 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384 ])
param postgresStorageSize int = 512

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

@secure()
@description('Comma-delimited user list for atlas. Do not use admin as a username. It causes problems with Atlas security')
param atlasUsersList string

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
//var vnetName = 'vnet-${suffix}'
var vnetName = 'DW_VNET-EastUS2'
var vnetAddressPrefix = '10.210.16.0/22'
var subnetNameApp = 'snet-${suffix}-webapp'
var subnetAddressPrefixApp = '10.210.16.0/26'
var subnetNameDB = 'snet-${suffix}-db'
var subnetAddressPrefixDB = '10.210.16.64/27'
var subnetNameSynapse = 'snet-${suffix}-synapse'
var subnetAddressPrefixSynapse = '10.210.16.96/27'
var subnetNamePE = 'snet-${suffix}-pe'
var subnetAddressPrefixPE = '10.210.16.128/27'

@description('Creates the app service plan')
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  #disable-next-line use-stable-resource-identifiers
  name: 'asp-${suffix}'
  location: location
  sku: {
    name: appPlanSkuName
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

@description('Creates the key vault')
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  #disable-next-line use-stable-resource-identifiers
  name: 'kv-${suffix}'
  location: location
  properties: {
    accessPolicies: []
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenantId
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

resource keyVaultDiagnosticLogs 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: keyVault.name
  scope: keyVault
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
//        retentionPolicy: {
//          days: 30
//          enabled: true
//        }
      }
    ]
  }
}

@description('Creates the integration VNet')
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

//Microsoft.Network/fpgaNetworkInterfaces,Microsoft.Web/serverFarms,Microsoft.ContainerInstance/containerGroups,Microsoft.Netapp/volumes,Microsoft.HardwareSecurityModules/dedicatedHSMs,Microsoft.ServiceFabricMesh/networks,Microsoft.Logic/integrationServiceEnvironments,Microsoft.Batch/batchAccounts,Microsoft.Sql/managedInstances,Microsoft.Sql/managedInstancesOnebox,Microsoft.Sql/managedInstancesTest,Microsoft.Sql/managedInstancesStage,Microsoft.Web/hostingEnvironments,Microsoft.BareMetal/CrayServers,Microsoft.BareMetal/MonitoringServers,Microsoft.Databricks/workspaces,Microsoft.BareMetal/AzureHostedService,Microsoft.BareMetal/AzureVMware,Microsoft.BareMetal/AzureHPC,Microsoft.BareMetal/AzurePaymentHSM,Microsoft.StreamAnalytics/streamingJobs,Microsoft.DBforPostgreSQL/serversv2,Microsoft.AzureCosmosDB/clusters,Microsoft.MachineLearningServices/workspaces,Microsoft.DBforPostgreSQL/singleServers,Microsoft.DBforPostgreSQL/flexibleServers,Microsoft.DBforMySQL/serversv2,Microsoft.DBforMySQL/flexibleServers,Microsoft.DBforMySQL/servers,Microsoft.ApiManagement/service,Microsoft.Synapse/workspaces,Microsoft.PowerPlatform/vnetaccesslinks,Microsoft.Network/dnsResolvers,Microsoft.Kusto/clusters,Microsoft.DelegatedNetwork/controller,Microsoft.ContainerService/managedClusters,Microsoft.PowerPlatform/enterprisePolicies,Microsoft.Network/virtualNetworkGateways,Microsoft.StoragePool/diskPools,Microsoft.DocumentDB/cassandraClusters,Microsoft.Apollo/npu,Microsoft.AVS/PrivateClouds,Microsoft.Orbital/orbitalGateways,Microsoft.Singularity/accounts/networks,Microsoft.Singularity/accounts/npu,Microsoft.ContainerService/TestClients,Microsoft.LabServices/labplans,Microsoft.Fidalgo/networkSettings,Microsoft.DevCenter/networkConnection,NGINX.NGINXPLUS/nginxDeployments,Microsoft.CloudTest/pools,Microsoft.CloudTest/hostedpools,Microsoft.CloudTest/images,Microsoft.Codespaces/plans,PaloAltoNetworks.Cloudngfw/firewalls,Qumulo.Storage/fileSystems,Microsoft.App/testClients,Microsoft.App/environments,Microsoft.ServiceNetworking/trafficControllers,GitHub.Network/networkSettings,Microsoft.Network/networkWatchers,Dell.Storage/fileSystems

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

output ohdsiWebapiUrl string = ohdsiWebApiWebapp.outputs.ohdsiWebapiUrl

@description('Creates the ohdsi achilles UI')
module achillesUI 'ohdsi_achilles.bicep' = {
  name: 'achillesUI'
  params: {
    location: location
    suffix: suffix
    appServicePlanId: appServicePlan.id
//    ohdsiWebApiUrl: ohdsiWebApiWebapp.outputs.ohdsiWebapiUrl
    keyVaultName: keyVault.name
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.id
    subnetID: vnet.properties.subnets[0].id
  }
  dependsOn: [
    ohdsiWebApiWebapp
  ]
}

resource atlasSecurityAdminSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'atlas-security-admin-password'
  parent: keyVault
  properties: {
    value: atlasSecurityAdminPassword
  }
}

var ohdsi_admin_connection_string = 'host=${atlasDatabase.outputs.postgresServerFullyQualifiedDomainName} port=5432 dbname=${atlasDatabase.outputs.postgresWebApiDatabaseName} user=${atlasDatabase.outputs.postgresWebapiAdminUsername} password=${postgresWebapiAdminPassword} sslmode=require'

resource deploymentAtlasSecurity 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'deployment-atlas-security'
  location: location
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.48.0'
    timeout: 'PT60M'
    forceUpdateTag: '5'
    containerSettings: {
      containerGroupName: 'deployment-atlas-security'
    }
    retentionInterval: 'PT1H'
    cleanupPreference: 'OnExpiration'
    environmentVariables: [
      {
        name: 'OHDSI_ADMIN_CONNECTION_STRING'
        secureValue: ohdsi_admin_connection_string
      }
      {
        name: 'ATLAS_SECURITY_ADMIN_PASSWORD'
        secureValue: atlasSecurityAdminPassword
      }
      {
        name: 'ATLAS_USERS'
        secureValue: 'admin,${atlasSecurityAdminPassword},${atlasUsersList}'
      }
      {
        name: 'SQL_ATLAS_CREATE_SECURITY'
        value: loadTextContent('sql/atlas_create_security.sql')
      }
      {
        name: 'WEBAPI_URL'
        value: ohdsiWebApiWebapp.outputs.ohdsiWebapiUrl
      }
    ]
    scriptContent: loadTextContent('scripts/atlas_security.sh')
  }
  dependsOn: [
    atlasDatabase
  ]
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  #disable-next-line use-stable-resource-identifiers
  name: 'log-${suffix}'
  location: location
}

resource deplymentAddDataSource 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'deployment-add-data-source'
  location: location
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.48.0'
    timeout: 'PT5M'
    forceUpdateTag: '6'
    containerSettings: {
      containerGroupName: 'deployment-add-data-source'
    }
    retentionInterval: 'PT1H'
    cleanupPreference: 'OnExpiration'
    environmentVariables: [
      {
        name: 'CONNECTION_STRING'
        secureValue: cdmDbType == 'PostgreSQL' ? omopCDMPostgres.outputs.OmopCdmJdbcConnectionString : omopCDMSynapse.outputs.OmopCdmJdbcConnectionString
      }
      {
        name: 'OHDSI_WEBAPI_PASSWORD'
        secureValue: atlasSecurityAdminPassword
      }
      {
        name: 'OHDSI_WEBAPI_USER'
        value: 'admin'
      }
      {
        name: 'OHDSI_WEBAPI_URL'
        value: ohdsiWebApiWebapp.outputs.ohdsiWebapiUrl
      }
      {
        name: 'DIALECT'
        value: cdmDbType == 'PostgreSQL' ? 'postgresql' : 'synapse'
      }
      {
        name: 'SOURCE_NAME'
        value: 'omop-cdm-synthea'
      }
      {
        name: 'SOURCE_KEY'
        value: 'omop-cdm-synthea'
      }
      {
        name: 'USERNAME'
        value: cdmDbType == 'PostgreSQL'? omopCDMPostgres.outputs.OmopCdmUser : omopCDMSynapse.outputs.OmopCdmUser
      }
      {
        name: 'PASSWORD'
        secureValue: OMOPCDMPassword
      }
      {
        name: 'DAIMON_CDM'
        value: 'cdm'
      }
      {
        name: 'DAIMON_VOCABULARY'
        value: 'cdm'
      }
      {
        name: 'DAIMON_RESULTS'
        value: 'cdm_results'
      }
      {
        name: 'DAIMON_TEMP'
        value: 'temp'
      }
      {
        name: 'OHDSI_ADMIN_CONNECTION_STRING'
        secureValue: ohdsi_admin_connection_string
      }
      {
        name: 'SQL_SOURCE_PERMISSIONS'
        value: loadTextContent('sql/atlas_add_source_permissions.sql')
      }
    ]
    scriptContent: loadTextContent('scripts/add_data_source.sh')
  }
  dependsOn: [
    deploymentAtlasSecurity
    ohdsiWebApiWebapp
    omopCDMPostgres
    omopCDMSynapse
  ]
}
