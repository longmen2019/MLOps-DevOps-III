terraform {
  required_version = ">= 1.6.0"

  backend "azurerm" {
    resource_group_name  = "rg-etcd"
    storage_account_name = "tfstateacctlongmen"
    container_name       = "tfstate"
    key                  = "backup/terraform.tfstate"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.24.0"
    }
  }
}

provider "azurerm" {
  features {}
}
