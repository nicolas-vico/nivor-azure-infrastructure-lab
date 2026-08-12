param location string
param environment string

var vnetAddressPrefix = '10.10.0.0/16'
var subnetAddressPrefix = '10.10.1.0/24'
var vnetName = 'vnet-niv-${environment}-01'

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location

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
