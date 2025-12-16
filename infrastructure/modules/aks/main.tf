# This is the "Prefab Component" - The reusable AKS Cluster Blueprint

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix

  default_node_pool {
    name       = "system"
    node_count = 1
    vm_size    = "Standard_B2s_v2" # Cheap system node
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = var.environment
  }
}

# The Spot Node Pool (Cost Savings)
resource "azurerm_kubernetes_cluster_node_pool" "spot" {
  name                  = "spotpool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = "Standard_D2s_v3"
  node_count            = 1
  priority              = "Spot"
  eviction_policy       = "Delete"
  spot_max_price        = -1
  node_taints           = ["kubernetes.azure.com/scalesetpriority=spot:NoSchedule"]
}