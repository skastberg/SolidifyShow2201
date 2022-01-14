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

targetScope = 'resourceGroup'

var sbtags = {
    usage: environmentType
    owner:'samuel'
  }

var sbtags2 = union(resourceGroup().tags, sbtags)


resource insights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${rootName}-insights-${environment}'
  location: location
  tags: sbtags2
  kind: 'web'
  properties: {
    Application_Type: 'web'
    RetentionInDays: 30
  }
}

///////////////////////////////////////////////////////////
// outputs
///////////////////////////////////////////////////////////
output insightsName string = insights.name
