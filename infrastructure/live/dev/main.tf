terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  
  helm = {
        source  = "hashicorp/helm"
        version = "~> 2.0"
      }

  kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14.0"
    }
    }
  backend "azurerm" {
      resource_group_name  = "rg-terraform-state"
      storage_account_name = "goldbeck789" 
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


# 1. Configure Helm to talk to your new AKS cluster
provider "helm" {
  kubernetes {
    host                   = module.aks_cluster.kube_config.0.host
    client_certificate     = base64decode(module.aks_cluster.kube_config.0.client_certificate)
    client_key             = base64decode(module.aks_cluster.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(module.aks_cluster.kube_config.0.cluster_ca_certificate)
  }
}

provider "kubectl" {
  host                   = module.aks_cluster.kube_config.0.host
  client_certificate     = base64decode(module.aks_cluster.kube_config.0.client_certificate)
  client_key             = base64decode(module.aks_cluster.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(module.aks_cluster.kube_config.0.cluster_ca_certificate)
  load_config_file       = false
}

# 2. Install ArgoCD automatically
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "5.51.6"

  # Save money by running low replicas
  set {
    name  = "server.replicas"
    value = "1"
  }
}


output "connect_command" {
  value = "az aks get-credentials --resource-group ${var.resource_group_name} --name ${var.cluster_name}"
}



# This automatically runs "kubectl apply -f application.yaml" for you
resource "kubectl_manifest" "argocd_app" {
    yaml_body = file("${path.module}/../../../gitops/clusters/dev/application.yaml")

    # Critical: Wait for ArgoCD to finish installing first
    depends_on = [helm_release.argocd]
}