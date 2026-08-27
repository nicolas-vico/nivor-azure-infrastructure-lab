@description('Azure region used for the lab deployment.')
param location string

@allowed([
  'dev'
  'test'
  'prod'
])
@description('Environment name used in resource names and governance tags.')
param environment string

var vnetAddressPrefix = '10.10.0.0/16'
var subnetAddressPrefix = '10.10.1.0/24'
var vnetName = 'vnet-niv-${environment}-01'
var commonTags = {
  Company: 'Nivor Systems'
  Environment: environment
  ManagedBy: 'Bicep'
  Workload: 'Networking'
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  tags: commonTags

  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  name: 'snet-servers-01'
  parent: vnet

  properties: {
    addressPrefix: subnetAddressPrefix
  }
}

output vnetName string = vnet.name
output vnetResourceId string = vnet.id
