terraform {
  required_version = ">= 0.12"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 1.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.4"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# ---------------------------------------------------------
# RANDOM + LOCALS
# ---------------------------------------------------------

resource "random_pet" "id" {}

resource "random_string" "fqdn" {
  length  = 6
  special = false
  upper   = false
  numeric = false
}

resource "random_password" "password" {
  count  = var.admin_password == null ? 1 : 0
  length = 20
}

locals {
  admin_password = try(random_password.password[0].result, var.admin_password)
}

# ---------------------------------------------------------
# RESOURCE GROUP + SIG
# ---------------------------------------------------------

resource "azurerm_resource_group" "vmss" {
  name     = var.packer_resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_shared_image_gallery" "sig" {
  name                = "myGallery"
  resource_group_name = azurerm_resource_group.vmss.name
  location            = azurerm_resource_group.vmss.location
}

resource "azurerm_shared_image" "win11_vdi" {
  name                = "myWin11VDIImage"
  gallery_name        = azurerm_shared_image_gallery.sig.name
  resource_group_name = azurerm_resource_group.vmss.name
  location            = azurerm_resource_group.vmss.location

  os_type            = "Windows"
  hyper_v_generation = "V2"

  identifier {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "office-365"
    sku       = "win11-23h2-avd-m365"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Latest SIG version produced by Packer
data "azurerm_shared_image_version" "latest" {
  name                = "latest" # or "1.0.0" if you want to pin
  image_name          = azurerm_shared_image.win11_vdi.name
  gallery_name        = azurerm_shared_image_gallery.sig.name
  resource_group_name = azurerm_resource_group.vmss.name
}

# ---------------------------------------------------------
# NETWORKING
# ---------------------------------------------------------

resource "azurerm_virtual_network" "vmss" {
  name                = "vmss-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.vmss.name
  tags                = var.tags
}

resource "azurerm_subnet" "vmss" {
  name                 = "vmss-subnet"
  resource_group_name  = azurerm_resource_group.vmss.name
  virtual_network_name = azurerm_virtual_network.vmss.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "vmss" {
  name                = "vmss-public-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.vmss.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = random_string.fqdn.result
  tags                = var.tags
}

resource "azurerm_lb" "vmss" {
  name                = "vmss-lb"
  location            = var.location
  resource_group_name = azurerm_resource_group.vmss.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.vmss.id
  }

  tags = var.tags
}

resource "azurerm_lb_backend_address_pool" "bpepool" {
  loadbalancer_id = azurerm_lb.vmss.id
  name            = "BackEndAddressPool"
}

resource "azurerm_lb_probe" "vmss" {
  loadbalancer_id = azurerm_lb.vmss.id
  name            = "rdp-probe"
  port            = 3389
}

resource "azurerm_lb_rule" "lbnatrule" {
  loadbalancer_id                = azurerm_lb.vmss.id
  name                           = "rdp"
  protocol                       = "Tcp"
  frontend_port                  = 3389
  backend_port                   = 3389
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.bpepool.id]
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = azurerm_lb_probe.vmss.id
}

# ---------------------------------------------------------
# (OPTIONAL) SSH KEY VIA AZAPI – NOT USED FOR WINDOWS, SAFE TO REMOVE
# ---------------------------------------------------------
# Keeping here commented in case you want it later
#
# resource "azapi_resource" "ssh_public_key" {
#   type      = "Microsoft.Compute/sshPublicKeys@2022-11-01"
#   name      = random_pet.id.id
#   location  = azurerm_resource_group.vmss.location
#   parent_id = azurerm_resource_group.vmss.id
# }
#
# resource "azapi_resource_action" "ssh_public_key_gen" {
#   type        = "Microsoft.Compute/sshPublicKeys@2022-11-01"
#   resource_id = azapi_resource.ssh_public_key.id
#   action      = "generateKeyPair"
#   method      = "POST"
#
#   response_export_values = ["publicKey", "privateKey"]
# }

# ---------------------------------------------------------
# VM SCALE SET (WINDOWS)
# ---------------------------------------------------------

resource "azurerm_windows_virtual_machine_scale_set" "vmss" {
  name                = "vmss"
  computer_name_prefix = "win11vdi"
  resource_group_name = azurerm_resource_group.vmss.name
  location            = azurerm_resource_group.vmss.location
  sku                 = "Standard_D2s_v3"
  instances           = 1

  source_image_id = data.azurerm_shared_image_version.latest.id

  admin_username = "azureuser"
  admin_password = "P@ssword123!"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  network_interface {
    name    = "nic"
    primary = true

    ip_configuration {
      name                                   = "ipconfig"
      subnet_id                              = azurerm_subnet.vmss.id
      load_balancer_backend_address_pool_ids = [
        azurerm_lb_backend_address_pool.bpepool.id
      ]
    }
  }
}

# ---------------------------------------------------------
# JUMPBOX VM (WINDOWS)
# ---------------------------------------------------------

resource "azurerm_public_ip" "jumpbox" {
  name                = "jumpbox-public-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.vmss.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "${random_string.fqdn.result}-ssh"
  tags                = var.tags
}

resource "azurerm_network_interface" "jumpbox" {
  name                = "jumpbox-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.vmss.name

  ip_configuration {
    name                          = "IPConfiguration"
    subnet_id                     = azurerm_subnet.vmss.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jumpbox.id
  }

  tags = var.tags
}

resource "azurerm_windows_virtual_machine" "jumpbox" {
  name                = "jumpbox"
  resource_group_name = azurerm_resource_group.vmss.name
  location            = azurerm_resource_group.vmss.location
  size                = "Standard_B2ms"

  admin_username = "azureuser"
  admin_password = "P@ssword123!"

  network_interface_ids = [
    azurerm_network_interface.jumpbox.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_id = data.azurerm_shared_image_version.latest.id
}
