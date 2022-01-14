@description('Will be used as prefix in name for resources')
param rootName string
@description('Location of the resource groups')
param location string = resourceGroup().location
@description('Environment identifier')
@allowed([
  'lab'
  'dev'
  'test'
  'prod'
])
param environment string = 'lab'
@description('What kind of environment we are installing. Allowed values "nonprod" or "prod"')
@allowed([
  'nonprod'
  'prod'
])
param environmentType string = 'nonprod'
@description('Name of the keyvault from where the function will read secrets')
param kvName string
@description('Name of resource group of the keyvault from where the function will read secrets')
param kvResourceGroup string
param ServiceNowConnectionName string
// -------------------------------
targetScope = 'resourceGroup'

var sbtags = {
  usage: environmentType
  owner: 'samuel'
}

var sbtags2 = union(resourceGroup().tags, sbtags)

// App Service plan
resource rServerFarm 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: '${rootName}-logicApps-${environment}'
  location: location
  tags: sbtags2
  properties: {
    zoneRedundant: false
    targetWorkerCount: 1
  }
  sku: {
    name: 'WS1'
    tier: 'WorkflowStandard'
  }
}

// Application insights, note 'existing'
resource rAppInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: '${rootName}-insights-${environment}'
}

// Storage account where the logic app will have all code
resource rStorageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: toLower('${rootName}stg${environment}')
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    allowSharedKeyAccess: true
    largeFileSharesState: 'Enabled'
    networkAcls: {
      resourceAccessRules: []
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

// The Logic App itself
resource rLogicApp 'Microsoft.Web/sites@2021-02-01' = {
  name: '${rootName}Workflows'
  location: location
  kind: 'functionapp,workflowapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: rServerFarm.id
    siteConfig: {
      use32BitWorkerProcess: true
      appSettings: [
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~14'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: rAppInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: rAppInsights.properties.ConnectionString
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${rStorageAccount.name};AccountKey=${rStorageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${rStorageAccount.name};AccountKey=${rStorageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower('${rootName}workflows9fa7')
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__id'
          value: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__version'
          value: '[1.*, 2.0.0)'
        }
        {
          name: 'APP_KIND'
          value: 'workflowApp'
        }
        {
          name: 'serviceBus_connectionString'
          value: '@Microsoft.KeyVault(SecretUri=https://${kvName}.vault.azure.net/secrets/solidifyshow-servicebus-connectionstring/)'
        }
        {
          name:'subscriptionId'
          value:subscription().subscriptionId
        }
        {
          name:'serviceNowConnectionRuntimeUrl'
          value: reference(resourceId('Microsoft.Web/connections', ServiceNowConnectionName), '2018-07-01-preview', 'full').properties.connectionRuntimeUrl
        }
      ]
    }
  }
}


// Add permissions to the logicApp to get values from key vault
var keyVaultPermissions = {
  secrets: [ 
    'get'
    'list'
  ]
}

// Since the Key Vault is in another resource group it needs to be in a module
module keyVault './kvPolicy.bicep' = {
  scope: resourceGroup(kvResourceGroup)
  name: 'keyVault'
  params: {
      keyVaultResourceName: kvName
      principalId: rLogicApp.identity.principalId
      keyVaultPermissions: keyVaultPermissions
      policyAction: 'add'
  }
}


output LogicAppName string = rLogicApp.name
output LogicAppObjectId string = rLogicApp.identity.principalId
