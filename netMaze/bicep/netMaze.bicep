@description('Enter the name of project')
param projectName string

@description('enter the env name')
param envName string

@allowed(['northeurope'
'westus'
'eastus'
'westeurope'
'centralindia'])
@description('enter the location')
param location string = 'westeurope'

@description('enter the storage name')
@minLength(4)
@maxLength(20)
param storageName string = 'pkp233${uniqueString(az.resourceGroup().id)}'

@allowed(['Standard_LRS'
'Standard_ZRS'
'Standard_GRS'
'Standard_GZRS'
'Premium_LRS'
'Premium_ZRS'
'Premium_GRS'])
param skuTypes string = 'Standard_LRS'

@description('enter address space of vnet')
param vnetPrefix string

@description('enter the prefix for web subnet:')
param webSubnetPrefix string

@description('enter the prefix for admin subnet:')
param adminSubnetPrefix string

@description('enter the prefix for db subnet:')
param dbSubnetPrefix string


@description('enter the offer will be used in VM:')
param vmOffer string = 'WindowsServer'


@description('enter the publisher that will be used in VM:')
param vmPublisher string = 'MicrosoftWindowsServer'

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
param vmSku string = '2022-datacenter-azure-edition'

@maxLength(10)
@minLength(2)
@description('enter the username of VM:')
param username string

@minLength(5)
@secure()
param password string


var vnetName = '${projectName}-${envName}-vnet'
var nicName = '${projectName}-${envName}-nic'
var nsgName = 'nsg-${projectName}-${envName}'
var webnsgName = 'webnsg-${projectName}-${envName}'


resource storage 'Microsoft.Storage/storageAccounts@2023-04-01' = {
  name:storageName
  kind:'StorageV2'
  location:location
  sku: {
    name: skuTypes
  }
  properties:{
    allowBlobPublicAccess:true
  }

}

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: nsgName
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
    ]
    
  }

}

resource webnsg 'Microsoft.Network/networkSecurityGroups@2023-11-01'= {
  name:webnsgName
  location:location
  properties:{
    securityRules:[
      {
        name:'allow-http'
        properties:{
          access:'Allow'
          direction:'Inbound'
          priority: 200
          protocol:'Tcp'
          sourcePortRange:'*'
          sourceAddressPrefix:'*'
          destinationPortRange:'80'
          destinationAddressPrefix:'*'
        }
      }
      {
        name:'allow-https'
        properties:{
          access:'Allow'
          direction:'Inbound'
          priority: 300
          protocol:'Tcp'
          sourcePortRange:'*'
          sourceAddressPrefix:'*'
          destinationPortRange:'443'
          destinationAddressPrefix:'*'

        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name:vnetName
  location:location
  properties:{
    addressSpace:{
      addressPrefixes:[
        vnetPrefix
      ]
    }
    subnets:[
      {
        name:'webapp-subnet'
        properties:{
          addressPrefix: webSubnetPrefix
          networkSecurityGroup:{
            id:webnsg.id
          }
        }
      }
      {
        name:'admin-subnet'
        properties:{
          addressPrefix:adminSubnetPrefix
          networkSecurityGroup:{
            id:nsg.id
          }
        }
      }
      {
        name:'db-subnet'
        properties:{
          addressPrefix:dbSubnetPrefix
          networkSecurityGroup:{
            id:nsg.id
          }
        }
      }
    ]
  }

}

resource nic 'Microsoft.Network/networkInterfaces@2023-11-01'= {
  name:'web-${nicName}'
  location:location
  properties:{
    ipConfigurations:[
      {
        name:'ipconfig1'
        properties:{
          privateIPAllocationMethod:'Dynamic'
          subnet:{
            id:vnet.properties.subnets[0].id
          }
        }
      }
    ]
  }
}

resource adminnic 'Microsoft.Network/networkInterfaces@2023-11-01'= {
  name:'admin-${nicName}'
  location:location
  properties:{
    ipConfigurations:[
      {
        name:'ipconfig1'
        properties:{
          privateIPAllocationMethod:'Dynamic'
          subnet:{
            id:vnet.properties.subnets[1].id
          }
        }
      }
    ]
  }
}

resource dbnic 'Microsoft.Network/networkInterfaces@2023-11-01'= {
  name:'db-${nicName}'
  location:location
  properties:{
    ipConfigurations:[
      {
        name:'ipconfig1'
        properties:{
          privateIPAllocationMethod:'Dynamic'
          subnet:{
            id:vnet.properties.subnets[2].id
          }
        }
      }
    ]
  }
}

resource publicip 'Microsoft.Network/publicIPAddresses@2023-11-01'={
  name:'${projectName}public-ip'
  location:location
  sku:{
    name:'Standard'
    tier:'Regional'
  }
  properties:{
    publicIPAddressVersion:'IPv4'
    publicIPAllocationMethod:'Static'
  }
}

resource LB 'Microsoft.Network/loadBalancers@2023-11-01'={
  name:'${projectName}-LB'
  sku:{
    name:'Standard'
    tier:'Regional'
  }
  location:location
  properties:{
    frontendIPConfigurations:[
      {
        name:'frontend-ip'
        properties:{
          publicIPAddress:{
            id:publicip.id
          }
        }
      }
    ]
    probes:[
      {
        name:'LB-probe'
        properties:{
          port:80
          protocol:'Tcp'
          intervalInSeconds: 5
          numberOfProbes: 5
        }
      }
    ]
    backendAddressPools:[
      {
        name:'LB-pools'
      }
    ]
    loadBalancingRules:[
      {
        name:'LB-rule'
        properties:{
          protocol:'Tcp'
          frontendPort:80
          backendPort:80
          idleTimeoutInMinutes:5
          enableTcpReset:false
          frontendIPConfiguration:{
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', '${projectName}-LB', 'frontend-ip')
          }
          backendAddressPool:{
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', '${projectName}-LB', 'LB-pools')
          }
          probe:{
            id:resourceId('Microsoft.Network/loadBalancers/probes', '${projectName}-LB', 'LB-probe')
          }
        }
      }
    ]
    inboundNatRules:[
      {
        name: 'lb-rdp'
        properties:{
          protocol:'Tcp'
          frontendPortRangeStart:1000
          frontendPortRangeEnd:1100
          frontendIPConfiguration:{
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', '${projectName}-LB', 'frontend-ip')
          }
          backendPort:3389
          idleTimeoutInMinutes:5
          enableFloatingIP:false
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2024-03-01'={
  name:'webvm-${projectName}'
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
        name:'webvm-osdisk'
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
      computerName:'webvm-${projectName}'
      windowsConfiguration:{
        enableAutomaticUpdates:true
      }
    }
    networkProfile:{
      networkInterfaces:[
        {
          id:nic.id
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
}

resource vm2 'Microsoft.Compute/virtualMachines@2024-03-01'={
  name:'dbvm-${projectName}'
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
        name:'dbvm-osdisk'
      }      
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
      computerName:'dbvm-${projectName}'
      windowsConfiguration:{
        enableAutomaticUpdates:true
      }
    }
    networkProfile:{
      networkInterfaces:[
        {
          id:adminnic.id
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
}
