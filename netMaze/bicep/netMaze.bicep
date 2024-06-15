@description('Enter the name of project')
param projectName string

@description('enter the env name')
param envName string

@description('enter the VM instances to deploy')
param vmCount int

@allowed(['northeurope'
'westus'
'eastus'
'eastasia'
'westeurope'
'centralindia'])
@description('enter the location')
param location string

@description('enter the storage name')
@minLength(4)
@maxLength(20)
param storageName string = uniqueString(az.resourceGroup().id)

@allowed(['Standard_LRS'
'Standard_ZRS'
'Standard_GRS'
'Standard_GZRS'
'Premium_LRS'
'Premium_ZRS'
'Premium_GRS'])
param skuTypes string

@description('enter address space of vnet')
param vnetPrefix string


@description('enter the offer will be used in VM:')
param vmOffer string


@description('enter the publisher that will be used in VM:')
param vmPublisher string

@allowed(['2016-datacenter-gensecond'
'2016-datacenter-server-core-g2'
'2016-datacenter-server-core-smalldisk-g2'
'2016-datacenter-smalldisk-g2'
'2016-datacenter-with-containers-g2'
'2016-datacenter-zhcn-g2'
'2019-datacenter-core-g2'
'2019-datacenter-core-smalldisk-g2'
'2019-datacenter-core-with-containers-g2'
'2019-datacenter-core-with-containers-smalldisk-g2'
'2019-datacenter-gensecond'
'2019-datacenter-smalldisk-g2'
'2019-datacenter-with-containers-g2'
'2019-datacenter-with-containers-smalldisk-g2'
'2019-datacenter-zhcn-g2'
'2022-datacenter-azure-edition'
'2022-datacenter-azure-edition-core'
'2022-datacenter-azure-edition-core-smalldisk'
'2022-datacenter-azure-edition-smalldisk'
'2022-datacenter-core-g2'
'2022-datacenter-core-smalldisk-g2'
'2022-datacenter-g2'
'2022-datacenter-smalldisk-g2'])
@description('enter the sku that will be used in VM:')
param vmSku string

@maxLength(10)
@minLength(2)
@description('enter the username of VM:')
param username string

@minLength(5)
@secure()
param password string


var vnetName = '${projectName}-${envName}-vnet'
var subnetName = '${envName}-subnet'
var nicName = '${envName}-nic'
var nsgName = 'nsg${projectName}-${envName}'


resource storage 'Microsoft.Storage/storageAccounts@2023-04-01' = {
  name:storageName
  kind:'StorageV2'
  location:location
  sku: {
    name: skuTypes
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = [for i in range(0, vmCount): {
  name: '${nsgName}${i}'
  location:location
  properties:{
    securityRules:[
      {
        name: 'allow-rdp'
        properties:{
          access:'Allow'
          direction:'Inbound'
          priority: 100
          protocol:'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '3389'
          destinationAddressPrefix: '*'

        }
      }
      {
        name: 'allow-http'
        properties:{
          access: 'Allow'
          direction: 'Inbound'
          priority: 101
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '80'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'allow-https'
        properties:{
          access: 'Allow'
          direction: 'Inbound'
          priority: 105
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
        }
      }
    ]
    
  }

}]

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name:vnetName
  location:location
  properties:{
    addressSpace:{
      addressPrefixes: [
        vnetPrefix
      ]
    }
  }
}

resource subnets 'Microsoft.Network/virtualNetworks/subnets@2023-11-01'= [for i in range(0, vmCount): {
  name: '${subnetName}${i}'
  parent: vnet
  properties: {
    addressPrefix: format('{0}.{1}.{2}.0/24', split(vnetPrefix, '.')[0],split(vnetPrefix, '.')[1], i)
    networkSecurityGroup:{
      id: nsg[i].id
    }
  }

}]



resource nic 'Microsoft.Network/networkInterfaces@2023-11-01'= [for i in range(0, vmCount): {
  name:'${nicName}${i}'
  location:location
  properties:{
    ipConfigurations:[
      {
        name:'ipconfig1'
        properties:{
          privateIPAllocationMethod:'Dynamic'
          subnet:{
            id:subnets[i].id
          }
          publicIPAddress:{
            id:publicip[i].id
          }
        }
      }
    ]
  }
}]

resource publicip 'Microsoft.Network/publicIPAddresses@2023-11-01'= [for i in range(0, vmCount): {
  name:'${projectName}${envName}-publicip${i}'
  location:location
  sku:{
    name:'Standard'
    tier:'Regional'
  }
  properties:{
    publicIPAddressVersion:'IPv4'
    publicIPAllocationMethod:'Static'
  }
}]

resource vm 'Microsoft.Compute/virtualMachines@2024-03-01'= [for i in range(0, vmCount): {  
  name:'${projectName}${envName}-vm${i}'
  location:location
  properties:{
    storageProfile:{
      imageReference:{
        offer: vmOffer
        publisher: vmPublisher
        sku: vmSku
        version:'latest'
      }
      osDisk:{
        createOption:'FromImage'
        caching: 'ReadWrite'
        name:'${envName}vm-osdisk${i}'
      }
      dataDisks:[
        {
          createOption: 'Empty'
          lun: 0
          caching:'ReadWrite'
          diskSizeGB:64
          
        }
      ]
    }
    securityProfile:{
      securityType:'TrustedLaunch'
      uefiSettings:{
        secureBootEnabled:true
        vTpmEnabled:true
      }
    }
    osProfile:{
      adminUsername: username
      adminPassword: password
      computerName:'${projectName}${envName}-vm${i}'
      windowsConfiguration:{
        enableAutomaticUpdates:true
      }
    }
    networkProfile:{
      networkInterfaces:[
        {
          id:nic[i].id
        }
      ]
    }
    hardwareProfile:{
      vmSize:'Standard_DS2_v2'
    }
    diagnosticsProfile:{
      bootDiagnostics:{
        enabled:true
      }
    }
  }
  dependsOn:[
    storage
  ]
}]

