data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "main" {
  name     = "crossplane-demo-rg"
  location = "westeurope"
}

resource "azurerm_kubernetes_cluster" "main" {
  name                   = "crossplane-demo-aks"
  location               = azurerm_resource_group.main.location
  resource_group_name    = azurerm_resource_group.main.name
  node_resource_group    = "crossplane-demo-aks-nodes-rg"
  dns_prefix             = "crossplane-demo-aks"
  sku_tier               = "Standard"
  local_account_disabled = true

  identity {
    type = "SystemAssigned"
  }

  azure_active_directory_role_based_access_control {
    managed            = true
    azure_rbac_enabled = true
  }

  default_node_pool {
    name                = "default"
    vm_size             = "Standard_D2ads_v5"
    os_sku              = "Ubuntu"
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 10
  }
}

resource "azurerm_role_assignment" "main" {
  scope                = azurerm_kubernetes_cluster.main.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = data.azurerm_client_config.current.object_id
}
