@description('Will be used as root name for resources and resource groups')
param rootName string
@description('Location of the resource groups')
param location string = resourceGroup().location

@description('What kind of environment we are installing. Allowed values "nonprod" or "prod"')
@allowed([
  'nonprod'
  'prod'
])
param environmentType string = 'nonprod'
@description('Environment identifier')
@allowed([
  'lab'
  'dev'
  'test'
  'prod'
])
param environment string = 'lab'
@secure()
param ServiceNowPassword string
param ServiceNowInstanceName string
param ServiceNowUsername string
param ServiceNowConnectionName string
param SettingsKvName string
param SettingsKvRg string

targetScope = 'resourceGroup'

// Application Insights
module appInsights 'Modules/ApplicationInsights.bicep' = {
  name: 'appInsights'
  params: {
    rootName: rootName
    location: location
    environment: environment
    environmentType: environmentType
  }
}

// Connection 
module snConnection 'Modules/ServiceNowConnection.bicep' = {
  name: 'ServiceNowConnection'
  params: {
    DisplayName: ServiceNowConnectionName
    Password: ServiceNowPassword
    ServiceNowInstanceName: ServiceNowInstanceName
    UserName: ServiceNowUsername
  }
}

// Logic App
module logicApp 'Modules/LogicApp.bicep' = {
  name: 'logicApp'
  dependsOn: [
    snConnection
  ]
  params: {
    rootName: rootName
    environment: environment
    environmentType: environmentType
    location: location
    kvName: SettingsKvName
    kvResourceGroup: SettingsKvRg
    ServiceNowConnectionName: ServiceNowConnectionName
  }
}

output TenantId string = subscription().tenantId
output SubscriptionId string = subscription().subscriptionId
output Location string = location
output ServiceNowConnectionName string = ServiceNowConnectionName
output LogicAppName string = logicApp.outputs.LogicAppName
output LogicAppObjectId string = logicApp.outputs.LogicAppObjectId
