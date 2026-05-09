terraform {
  required_version = ">= 1.5.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.24.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
  }

  # Optional remote backend
   backend "azurerm" {
     resource_group_name  = "rg-etcd"
     storage_account_name = "tfstateacctlongmen"
     container_name       = "tfstate"
     key                  = "etcd/terraform.tfstate"
   }
}

provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kubeconfig_context
}

provider "azurerm" {
  features {}
}

