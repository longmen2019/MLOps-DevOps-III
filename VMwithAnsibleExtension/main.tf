#########################################################
#RESOURCE GROUP
#########################################################
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name 
  location = var.location
  tags = { 
    Environment = var.environment_tag 
   }
}
#########################################################
#VIRTUAL NETWORK
#########################################################
resource "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network_name
  address_space       = var.address_space 
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags = { 
    Environment = var.environment_tag
   }
}
#########################################################
#SUBNET 
#########################################################
resource "azurerm_subnet" "snet" {
  name                 = var.subnet_name 
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name 
  address_prefixes     = var.address_prefixes  
}

#NSG Access Rules for Lab
#Get Client IP Address for NSG
data "http" "clientip" {
  url = "https://ipv4.icanhazip.com/"
}

#########################################################
#NETWORK SECURITY GROUP 
#########################################################

resource "azurerm_network_security_group" "nsg" {
  name                = var.network_security_group_name 
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH-In"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "${chomp(data.http.clientip.response_body)}/32"
    destination_address_prefix = "*"
  }

  tags = {
    environment = var.environment_tag
  }
}
#########################################################
#SUBNET NETWORK SECURITY GROUP ASSOCIATION
#########################################################

resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.snet.id 
  network_security_group_id = azurerm_network_security_group.nsg.id 
}

resource "random_id" "server" {
  prefix = "ansible"
  byte_length = 5
}
#Keyvault Creation
data "azurerm_client_config" "current" {}

#########################################################
#KEY VAULT
#########################################################

resource "azurerm_key_vault" "key_vault" {
  name                        = var.key_vault_name
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  depends_on                = [azurerm_resource_group.rg]

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
  "Backup",
  "Create",
  "Decrypt",
  "Delete",
  "Encrypt",
  "Get",
  "Import",
  "List",
  "Purge",
  "Recover",
  "Restore",
  "Sign",
  "UnwrapKey",
  "Update",
  "Verify",
  "WrapKey",
  "Release",
  "Rotate",
  "GetRotationPolicy",
  "SetRotationPolicy"
]

secret_permissions = [
  "Backup",
  "Delete",
  "Get",
  "List",
  "Purge",
  "Recover",
  "Restore",
  "Set"
]

storage_permissions = [
  "Backup",
  "Delete",
  "DeleteSAS",
  "Get",
  "GetSAS",
  "List",
  "ListSAS",
  "Purge",
  "Recover",
  "RegenerateKey",
  "Restore",
  "Set",
  "SetSAS",
  "Update"
]  
  }
  tags = {
    Environment = var.environment_tag
  }
}

#########################################################
#RANDOM PASSWORD
#########################################################
resource "random_password" "anpassword" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

#########################################################
#KEY VAULT SECRET
#########################################################

resource "azurerm_key_vault_secret" "key_vault_secret" {
  name         = var.key_vault_secret_name
  value        = random_password.anpassword.result 
  key_vault_id = azurerm_key_vault.key_vault.id
  depends_on   = [azurerm_key_vault.key_vault]
}

#########################################################
#PUBLIC IP
#########################################################

resource "azurerm_public_ip" "pip" {
  name                = var.public_ip_name 
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    environment = var.environment_tag
  }
}

#########################################################
#NETWORK INTERFACE & PUBLIC IP & PRIVATE IP
#########################################################

resource "azurerm_network_interface" "nic" {
  name                = var.network_interface_name 
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ansible01-ipconfig"
    subnet_id                     = azurerm_subnet.snet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          =azurerm_public_ip.pip.id 
  }
  tags = {
    Environment = var.environment_tag
  }
}

#########################################################
#VIRTUAL MACHINE
#########################################################

resource "azurerm_linux_virtual_machine" "vm" {
  name                = var.virtual_machine_name 
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.vm_size 
  admin_username      = var.admin_username
  admin_password      = azurerm_key_vault_secret.key_vault_secret.value
  disable_password_authentication   = false 
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]


  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  tags = {
    Environment = var.environment_tag
  }
}

#########################################################
#VIRTUAL MACHINE
########################################################

resource "azurerm_virtual_machine_extension" "ansibe-base-setup" {
  name                 = "ansible-basesetup"
  virtual_machine_id   = azurerm_linux_virtual_machine.vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "bash AnsibleSetup.sh",
        "fileUris": [
          "https://raw.githubusercontent.com/longmen2022/AnsibleExtensionAzure/refs/heads/main/Ansible/AnsibleSetup.sh"
        ]
    }
SETTINGS


  tags = {
    Environment = var.environment_tag
  }
}