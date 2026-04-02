terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "azurerm" {
  features {}
}

# ---------------------------------------------------------
# Resource Group (West Europe)
# ---------------------------------------------------------
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group
  location = var.location
  tags     = var.tags
}

# ---------------------------------------------------------
# Virtual Network (West Europe)
# ---------------------------------------------------------
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

# ---------------------------------------------------------
# Subnet
# ---------------------------------------------------------
resource "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_prefix]
}

# ---------------------------------------------------------
# NSG for control-plane SSH
# ---------------------------------------------------------
resource "azurerm_network_security_group" "cp_nsg" {
  name                = "cp-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "allow_ssh_anywhere" {
  name                        = "Allow-SSH-Anywhere"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.cp_nsg.name
}

# ---------------------------------------------------------
# Public IP for control-plane
# ---------------------------------------------------------
resource "azurerm_public_ip" "cp_pip" {
  name                = "cp-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# ---------------------------------------------------------
# NICs
# ---------------------------------------------------------
resource "azurerm_network_interface" "cp_nic" {
  name                = "cp-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.cp_pip.id
  }
}

resource "azurerm_network_interface_security_group_association" "cp_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.cp_nic.id
  network_security_group_id = azurerm_network_security_group.cp_nsg.id
}

resource "azurerm_network_interface" "worker1_nic" {
  name                = "worker1-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "worker2_nic" {
  name                = "worker2-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# ---------------------------------------------------------
# Control-plane VM
# ---------------------------------------------------------
resource "azurerm_linux_virtual_machine" "cp" {
  name                = "cp"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.vm_size_cp
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.cp_nic.id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

# ---------------------------------------------------------
# Worker VMs
# ---------------------------------------------------------
resource "azurerm_linux_virtual_machine" "worker1" {
  name                = "worker1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.vm_size_worker1
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.worker1_nic.id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

resource "azurerm_linux_virtual_machine" "worker2" {
  name                = "worker2"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.vm_size_worker2   # B1ms to fit quota
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.worker2_nic.id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

# ---------------------------------------------------------
# Jump Host Public IP
# ---------------------------------------------------------
resource "azurerm_public_ip" "jump_pip" {
  name                = "jump-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# ---------------------------------------------------------
# Jump Host NSG
# ---------------------------------------------------------
resource "azurerm_network_security_group" "jump_nsg" {
  name                = "jump-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "jump_ssh" {
  name                        = "Allow-SSH-Anywhere"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.jump_nsg.name
}

# ---------------------------------------------------------
# Jump Host NIC
# ---------------------------------------------------------
resource "azurerm_network_interface" "jump_nic" {
  name                = "jump-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jump_pip.id
  }
}

resource "azurerm_network_interface_security_group_association" "jump_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.jump_nic.id
  network_security_group_id = azurerm_network_security_group.jump_nsg.id
}

# ---------------------------------------------------------
# Jump Host VM
# ---------------------------------------------------------
resource "azurerm_linux_virtual_machine" "jump" {
  name                = "jump-host"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.vm_size_jump
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.jump_nic.id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}
