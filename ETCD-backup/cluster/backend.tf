terraform {
  required_version = ">= 1.6.0"

  backend "azurerm" {
    resource_group_name  = "rg-etcd"
    storage_account_name = "tfstateacctlongmen"
    container_name       = "tfstate"
    key                  = "cluster/terraform.tfstate"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}
