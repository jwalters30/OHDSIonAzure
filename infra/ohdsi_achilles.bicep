param location string
param suffix string
param appServicePlanId string
param logAnalyticsWorkspaceId string
param subnetID string

var dockerRegistryServer = 'https://index.docker.io/v1'
var dockerImageName = 'ohdsi/broadsea-achilles'
//var dockerImageName = 'rocker/rstudio'
var dockerImageTag = 'sha-c40e549'
//var dockerImageTag = 'latest'
//var shareName = 'achilles'
//var mountPath = '/etc/achilles'
var logCategories = ['AppServiceAppLogs', 'AppServiceConsoleLogs', 'AppServiceHTTPLogs']

/*
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: 'stohdsi${suffix}'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }

  resource fileService 'fileServices' = {
    name: 'default'

    resource share 'shares' = {
      name: shareName
    }
  }
}

resource deploymentOhdsiAtlasConfigScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'deployment-ohdsi-atlas-config-file'
  location: location
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.48.0'
    timeout: 'PT5M'
    retentionInterval: 'PT1H'
    environmentVariables: [
      {
        name: 'AZURE_STORAGE_ACCOUNT'
        value: storageAccount.name

      }
      {
        name: 'AZURE_STORAGE_KEY'
        secureValue: storageAccount.listKeys().keys[0].value
      }
      {
        name: 'OHDSI_WEBAPI_URL'
        value: ohdsiWebApiUrl
      }

      {
        name: 'CONTENT'
        value: loadTextContent('scripts/config-local.js')
      }
      {
        name: 'SHARE_NAME'
        value: shareName
      }
    ]
    scriptContent: '''
    apk --update add gettext
    echo "$CONTENT" > config-local-temp.js
    envsubst < config-local-temp.js > config-local.js
    az storage file upload --source config-local.js -s $SHARE_NAME
    '''
  }
}
*/

resource uiWebApp 'Microsoft.Web/sites@2022-03-01' = {
  name: 'app-ohdsiachilles-${suffix}'
  location: location
  properties: {
    httpsOnly: true
    clientAffinityEnabled: false
    serverFarmId: appServicePlanId
    virtualNetworkSubnetId: subnetID
    siteConfig: {
      /*
      azureStorageAccounts: {
        '${shareName}': {
          type: 'AzureFiles'
          shareName: shareName
          mountPath: mountPath
          accountName: storageAccount.name
          accessKey: storageAccount.listKeys().keys[0].value
        }
      }
      */
      vnetRouteAllEnabled: true
      linuxFxVersion: 'DOCKER|${dockerImageName}:${dockerImageTag}'
      ftpsState: 'Disabled'
      appSettings: [
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: dockerRegistryServer
        }
        {
          name: 'WEBSITE_HEALTHCHECK_MAXPINGFAILURES'
          value: '10'
        }
        {
          name: 'WEBSITE_HTTPLOGGING_RETENTION_DAYS'
          value: '30'
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'WEBSITES_PORT'
          value: '8087'
        }
        {
          name: 'ACHILLES_DB_URI'
          value: 'postgresql://host.docker.internal:5432/postgres'
        }
        {
          name: 'ACHILLES_DB_USERNAME'
          value: 'postgres_user'
        }
        {
          name: 'ACHILLES_DB_PASSWORD'
          value: 'postgres_password'
        }
      ]
    }
  }
  /*
  dependsOn: [
    deploymentOhdsiAtlasConfigScript
  ]
  */
}

resource diagnosticLogs 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: uiWebApp.name
  scope: uiWebApp
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [for logCategory in logCategories: {
      category: logCategory
      enabled: true
      retentionPolicy: {
        days: 30
        enabled: true
      }
    }]
  }
}
