terraform {
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.3"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = ">= 1.2.28"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.31"
    }
  }
}

provider "azurerm" {
  features {}
}

