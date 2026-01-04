# infrastructure/modules/aks/network.tf

resource "azurerm_virtual_network" "aks_vnet" {
  name                = "aks-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/8"]
}

# Room 1: The AKS Cluster lives here
resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = ["10.240.0.0/16"]
}

# Room 2: The WAF lives here (Must be empty!)
resource "azurerm_subnet" "waf_subnet" {
  name                 = "waf-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = ["10.2.0.0/24"]
}

# Public IP for the WAF
resource "azurerm_public_ip" "waf_public_ip" {
  name                = "waf-public-ip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}