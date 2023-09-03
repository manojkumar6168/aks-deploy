@description('Location for all resources.')
param location string = resourceGroup().location

@description('Virtual Network Name')
param vnet_name string = 'aks-vnet'

@description('Virtual Network Address Prefix')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('AKS Subnet Name')
param aks_subnet string = 'aks-subnet'

@description('AKS Subnet Address Prefix')
param aks_subnetPrefix string = '10.0.0.0/21'

@description('PostgreSQL Subnet Name')
param postgresql_subnet string = 'postgresql_subnet'

@description('Subnet Address Prefix')
param postgresubnetPrefix string = '10.0.8.0/24'

@description('Specifies the name of the AKS cluster.')
param ClusterName string = 'aks-${uniqueString(resourceGroup().id)}'

@description('Specifies the OS Disk Size in GB to be used to specify the disk size for every machine in this master/agent pool. If you specify 0, it will apply the default osDisk size according to the vmSize specified..')
param osDiskSizeGB int = 128

@description('The number of nodes for the cluster. 1 Node is enough for Dev/Test and minimum 3 nodes, is recommended for Production')
@minValue(1)
@maxValue(10)
param agentCount int = 1

@description('The size of the Virtual Machine.')
param agentVMSize string = 'Standard_D2s_v3'

@description('Specifies whether to create the cluster as a private cluster or not.')
param aksClusterEnablePrivateCluster bool = true

@description('Specifies the DNS prefix specified when creating the managed cluster.')
param dnsPrefix string = ClusterName

@description('Specifies the tier of a managed cluster SKU: Paid or Free')
@allowed([
  'Paid'
  'Free'
])
param aksClusterSkuTier string = 'Paid'

@description('Name of the azure container registry (must be globally unique)')
@minLength(5)
@maxLength(50)
param acrName string = 'acr${uniqueString(resourceGroup().id)}'

@description('Enable an admin user that has push/pull permission to the registry.')
param acrAdminUserEnabled bool = true

@description('Tier of your Azure Container Registry.')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param acrSku string = 'Basic'

@description('Server Name for Azure Database for PostgreSQL')
param serverName string = ClusterName

@description('Database administrator login name')
@minLength(1)
param administratorLogin string = 'azureuser'

@description('Database administrator password')
@minLength(8)
@secure()
param administratorLoginPassword string = 'RoyalInfo@123'

@description('Azure Database for PostgreSQL compute capacity in vCores (2,4,8,16,32)')
param skuCapacity int = 2

@description('Azure Database for PostgreSQL sku name ')
param skuName string = 'GP_Gen5_2'

@description('Azure Database for PostgreSQL Sku Size ')
param skuSizeMB int = 51200

@description('Azure Database for PostgreSQL pricing tier')
@allowed([
  'Basic'
  'GeneralPurpose'
  'MemoryOptimized'
])
param skuTier string = 'GeneralPurpose'

@description('Azure Database for PostgreSQL sku family')
param skuFamily string = 'Gen5'

@description('PostgreSQL version')
@allowed([
  '9.5'
  '9.6'
  '10'
  '10.0'
  '10.2'
  '11'
])
param postgresqlVersion string = '11'

@description('PostgreSQL Server backup retention days')
param backupRetentionDays int = 7

@description('Geo-Redundant Backup setting')
param geoRedundantBackup string = 'Disabled'

@description('Specifies the name of the virtual machine.')
param vmName string = 'Jump-Srv'

@description('Specifies the size of the virtual machine.')
param vmSize string = 'Standard_B2s'

@description('Specifies the image publisher of the disk image used to create the virtual machine.')
param imagePublisher string = 'Canonical'

@description('Specifies the offer of the platform image or marketplace image used to create the virtual machine.')
param imageOffer string = 'UbuntuServer'

@description('Specifies the Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version.')
param imageSku string = '18.04-LTS'

@description('Specifies the name of the administrator account of the virtual machine.')
param vmAdminUsername string = 'azureuser'

@description('Specifies the type of authentication when accessing the Virtual Machine. SSH key is recommended.')
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'password'

@description('Specifies the SSH Key or password for the virtual machine. SSH key is recommended.')
@secure()
param vmAdminPasswordOrKey string

@description('Specifies the storage account type for OS and data disk.')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GZRS'
  'Standard_RAGZRS'
])
param diskStorageAccounType string = 'Standard_LRS'

@description('Specifies the size in GB of the OS disk of the VM.')
param osDiskSize int = 30

@description('Specifies the globally unique name for the storage account used to store the boot diagnostics logs of the virtual machine.')
param blobStorageAccountName string = 'boot${uniqueString(resourceGroup().id)}'

@description('Specifies the name of the private link to the boot diagnostics storage account.')
param blobStorageAccountPrivateEndpointName string = 'BlobStorageAccountPrivateEndpoint'

var vnetId = vnet_name_resource.id
var vmSubnetId = vnet_name_postgresql_subnet.id
var vmNicName = '${vmName}Nic'
var vmNicId = vmNic.id
var blobStorageAccountId = blobStorageAccount.id
var blobPublicDNSZoneForwarder = '.blob.${environment().suffixes.storage}'
var blobPrivateDnsZoneName = 'privatelink${blobPublicDNSZoneForwarder}'
var blobPrivateDnsZoneId = blobPrivateDnsZone.id
var blobStorageAccountPrivateEndpointGroupName = 'blob'
var blobPrivateDnsZoneGroup_var = '${blobStorageAccountPrivateEndpointName}/${blobStorageAccountPrivateEndpointGroupName}PrivateDnsZoneGroup'
var blobStorageAccountPrivateEndpointId = blobStorageAccountPrivateEndpoint.id
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${vmAdminUsername}/.ssh/authorized_keys'
        keyData: vmAdminPasswordOrKey
      }
    ]
  }
  provisionVMAgent: true
}
var bastionPublicIpAddressName = '${vmName}PublicIp'

resource vnet_name_resource 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: vnet_name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
  }
}

resource vnet_name_aks_subnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' = {
  parent: vnet_name_resource
  name: '${aks_subnet}'
  properties: {
    addressPrefix: aks_subnetPrefix
  }
}

resource vnet_name_postgresql_subnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' = {
  parent: vnet_name_resource
  name: '${postgresql_subnet}'
  properties: {
    addressPrefix: postgresubnetPrefix
  }
}

resource cluster 'Microsoft.ContainerService/managedClusters@2022-05-02-preview' = {
  name: ClusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: dnsPrefix
    sku: {
      name: 'Basic'
      tier: aksClusterSkuTier
    }
    agentPoolProfiles: [
      {
        name: 'agentpool'
        osDiskSizeGB: osDiskSizeGB
        count: agentCount
        vmSize: agentVMSize
        osType: 'Linux'
        mode: 'System'
      }
    ]
    apiServerAccessProfile: {
      enablePrivateCluster: aksClusterEnablePrivateCluster
    }
  }
}

resource acr 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: acrName
  location: location
  tags: {
    displayName: 'Container Registry'
    'container.registry': acrName
  }
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: acrAdminUserEnabled
  }
}

resource server 'Microsoft.DBforPostgreSQL/servers@2017-12-01' = {
  name: serverName
  location: location
  sku: {
    name: skuName
    tier: skuTier
    capacity: skuCapacity
    size: skuSizeMB
    family: skuFamily
  }
  properties: {
    createMode: 'Default'
    version: postgresqlVersion
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    storageProfile: {
      storageMB: skuSizeMB
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: geoRedundantBackup
    }
  }
}

resource blobPrivateDnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: blobPrivateDnsZoneName
  location: 'global'
  properties: {
    maxNumberOfRecordSets: 25000
    maxNumberOfVirtualNetworkLinks: 1000
    maxNumberOfVirtualNetworkLinksWithRegistration: 100
  }
}

resource blobPrivateDnsZoneName_link_to_vnet_name 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: blobPrivateDnsZone
  name: 'link_to_${toLower(vnet_name)}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
  dependsOn: [
    blobPrivateDnsZoneId
    vnetId
  ]
}

resource blobStorageAccountPrivateEndpoint 'Microsoft.Network/privateEndpoints@2020-04-01' = {
  name: blobStorageAccountPrivateEndpointName
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: blobStorageAccountPrivateEndpointName
        properties: {
          privateLinkServiceId: blobStorageAccountId
          groupIds: [
            blobStorageAccountPrivateEndpointGroupName
          ]
        }
      }
    ]
    subnet: {
      id: vmSubnetId
    }
    customDnsConfigs: [
      {
        fqdn: concat(blobStorageAccountName, blobPublicDNSZoneForwarder)
      }
    ]
  }
  dependsOn: [
    vnetId
    blobStorageAccountId
  ]
}

resource blobPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  name: blobPrivateDnsZoneGroup_var
  location: location
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'dnsConfig'
        properties: {
          privateDnsZoneId: blobPrivateDnsZoneId
        }
      }
    ]
  }
  dependsOn: [
    blobPrivateDnsZoneId
    blobStorageAccountPrivateEndpointId
  ]
}

resource bastionPublicIpAddress 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: bastionPublicIpAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource blobStorageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: blobStorageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource vmNic 'Microsoft.Network/networkInterfaces@2020-04-01' = {
  name: vmNicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vmSubnetId
          }
        }
      }
    ]
  }
  dependsOn: [
    vnetId
  ]
}

resource vm 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: vmAdminUsername
      adminPassword: vmAdminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSku
        version: 'latest'
      }
      osDisk: {
        name: '${vmName}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        diskSizeGB: osDiskSize
        managedDisk: {
          storageAccountType: diskStorageAccounType
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmNic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(blobStorageAccountId).primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    vmNicId

  ]
}