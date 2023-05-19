param baseName string
param location string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-11-01' = {
  name: '${baseName}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.10.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'aks'
        properties: {
          addressPrefix: '10.10.0.0/16'
        }
      }
    ]
  }
  resource aks 'subnets' existing = {
    name: 'aks'
  }
}

resource aks 'Microsoft.ContainerService/managedClusters@2023-03-01' = {
  name: '${baseName}-aks'
  location: location
  sku: {
    name: 'Base'
    tier: 'Standard'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    aadProfile: {
      managed: true
      enableAzureRBAC: true
    }
    kubernetesVersion: '1.26.3'
    agentPoolProfiles: [
      {
        name: 'agentpool'
        availabilityZones: [
          '1'
          '2'
          '3'
        ]
        count: 1
        minCount: 1
        maxCount: 5
        enableAutoScaling: true
        mode: 'System'
        maxPods: 250
        osType: 'Linux'
        osDiskType: 'Ephemeral'
        osSKU: 'Ubuntu'
        vmSize: 'Standard_D2ads_v5'
        osDiskSizeGB: 75
        vnetSubnetID: virtualNetwork::aks.id
        type: 'VirtualMachineScaleSets'
        upgradeSettings: {
          maxSurge: '33%'
        }
      }
    ]
    disableLocalAccounts: true
    dnsPrefix: '${baseName}-aks'
    nodeResourceGroup: '${baseName}-aks-nodes-rg'
    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: 'azure'
      loadBalancerSku: 'standard'
      
    }
  }
}
