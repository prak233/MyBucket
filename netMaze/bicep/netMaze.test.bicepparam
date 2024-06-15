using 'netMaze.bicep'

param vmCount = 3
param location = 'eastasia'
param storageName = 'pkp233'
param envName = 'Test'
param projectName = 'Netmaze'
param username = 'pratul'
param password = 'coforge@1234'
param skuTypes = 'Standard_LRS'
param vnetPrefix = '192.168.0.0/16'
param vmOffer = 'WindowsServer'
param vmPublisher = 'MicrosoftWindowsServer'
param vmSku = '2022-datacenter-azure-edition'
