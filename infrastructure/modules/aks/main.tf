resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix


  # FIX 2: Explicitly enable Role-Based Access Control (RBAC)
  role_based_access_control_enabled = true

  default_node_pool {
    name       = "system"
    node_count = 1
    vm_size    = "Standard_B2s_v2"
    vnet_subnet_id = azurerm_subnet.aks_subnet.id
  }

  identity {
    type = "SystemAssigned"
  }

  # FIX 3: Enable Network Policy (using Azure's native implementation)
  network_profile {
    network_plugin = "azure"
    network_policy = "azure" # This blocks unauthorized Pod-to-Pod traffic
    service_cidr   = "10.0.0.0/16" 
    dns_service_ip = "10.0.0.10"
  }

# NEW: Connect the WAF (AGIC)
  ingress_application_gateway {
    gateway_id = azurerm_application_gateway.network.id
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
  vnet_subnet_id  = azurerm_subnet.aks_subnet.id
}