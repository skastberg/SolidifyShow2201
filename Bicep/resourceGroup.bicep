@description('Will be used as root name for resources and resource groups')
param rootName string
@description('Location of the resource groups')
@allowed([
  'westeurope'
  'eastus'
])
param location string = 'westeurope'

@description('What kind of environment we are installing. Allowed values "nonprod" or "prod"')
@allowed([
  'nonprod'
  'prod'
])
param environmentType string = 'nonprod'

targetScope = 'subscription'

var departmentTag = 'Samuels R&D'

// Resource group common resources
resource commonGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${rootName}-rg'
  location: location  
  tags: {
    'department':departmentTag
    'level':environmentType
  }
}




output commonResourceGroup string = commonGroup.name
