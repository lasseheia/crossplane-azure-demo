terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.58.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "main" {
  name     = "crossplane-demo-rg"
  location = "West Europe"
}

resource "azurerm_network_security_group" "main" {
  name                = "crossplane-demo-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_virtual_network" "main" {
  name                = "crossplane-demo-vnet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]

  subnet {
    name           = "aks"
    address_prefix = "10.0.0.0/20"
    security_group = azurerm_network_security_group.main.id
  }
}

data "azurerm_subnet" "aks" {
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  name                 = "aks"
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = "crossplane-demo-aks"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "crossplane-demo-aks"
  node_resource_group = "crossplane-demo-aks-nodes-rg"
  sku_tier = "Standard"

  identity {
    type = "SystemAssigned"
  }

  azure_active_directory_role_based_access_control {
    managed = true
    azure_rbac_enabled = true
    tenant_id = data.azurerm_client_config.current.tenant_id
  }

  default_node_pool {
    name       = "default"
    vm_size    = "Standard_D2ads_v5"
    os_sku = "Ubuntu"
    os_disk_size_gb = 0
    os_disk_type = "Ephemeral"
    type = "VirtualMachineScaleSets"
    enable_auto_scaling = true
    node_count = 1
    min_count = 1
    max_count = 3
    zones = [1, 2, 3]
    pod_subnet_id = data.azurerm_subnet.aks.id
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "calico"
  }

}
