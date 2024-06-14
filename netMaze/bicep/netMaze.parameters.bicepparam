using 'netMaze.bicep'

param location = null
param storageName = null
param envName = 'prod'
param projectName = 'netmaze'
param username = 'pratul'
param password = 'coforge@1234'
param skuTypes = null
param vnetPrefix = '192.168.0.0/16'
param webSubnetPrefix = '192.168.0.0/24'
param adminSubnetPrefix = '192.168.1.0/24'
param dbSubnetPrefix = '192.168.2.0/24'
param vmOffer = null
param vmPublisher = null
param vmSku = null
