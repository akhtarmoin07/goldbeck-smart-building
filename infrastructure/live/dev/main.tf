terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
      resource_group_name  = "goldbeck-smart-building-tfstate-rg"
      storage_account_name = "goldbecktfstatev2" 
      container_name       = "tfstate"
      key                  = "dev.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# 1. Create Resource Group using Variable
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# 2. Call Module using Variables
module "aks_cluster" {
  source              = "../../modules/aks"
  
  # Pass the variables from tfvars into the module
  cluster_name        = var.cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.dns_prefix
  environment         = var.environment
}

output "connect_command" {
  value = "az aks get-credentials --resource-group ${var.resource_group_name} --name ${var.cluster_name}"
}