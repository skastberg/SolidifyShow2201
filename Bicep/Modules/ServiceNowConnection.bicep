@description('Connection DisplayName')
param DisplayName string 
param ServiceNowInstanceName string 
param UserName string
@secure()
param Password string


targetScope = 'resourceGroup'

var connections_service_now_name  = 'service-now'

resource connections_service_now_name_resource 'Microsoft.Web/connections@2016-06-01' = {
  name: DisplayName
  location: resourceGroup().location
  kind: 'V2'

  properties: {
    displayName: DisplayName
    statuses: [
      {
        status: 'Connected'
      }
    ]
    customParameterValues: {}
    nonSecretParameterValues: {

    }
    parameterValues: {
      instance: 'https://${ServiceNowInstanceName}.${connections_service_now_name}.com/'
      username: UserName
      password: Password
    }
    api: {
      name: connections_service_now_name
      displayName: 'ServiceNow'
      description: 'ServiceNow improves service levels, energizes employees, and enables your enterprise to work at lightspeed. Create, read and update records stored within ServiceNow including Incidents, Questions, Users and more.'
      iconUri: 'https://connectoricons-prod.azureedge.net/releases/v1.0.1544/1.0.1544.2640/${connections_service_now_name}/icon.png'
      brandColor: '#D1232B'
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${resourceGroup().location}/managedApis/${connections_service_now_name}'
      type: 'Microsoft.Web/locations/managedApis'
    }
    testLinks: [
      {
        requestUri: 'https://management.azure.com:443/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Web/connections/${DisplayName}/extensions/proxy/api/now/doc/table/schema?api-version=2016-06-01'
        method: 'get'
      }
    ]
  }
}


