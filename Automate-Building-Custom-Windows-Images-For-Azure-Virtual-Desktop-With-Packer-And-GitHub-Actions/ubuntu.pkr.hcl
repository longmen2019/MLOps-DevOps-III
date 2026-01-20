packer {
  required_plugins {
    azure = {
      source  = "github.com/hashicorp/azure"
      version = "~> 1"
    }
  }
}

variable "location" { default = "northeurope" }
variable "image_resource_group_name" { default = "myPackerImages" }
variable "oidc_request_url"   { default = null }
variable "oidc_request_token" { default = null }

source "azure-arm" "builder" {
  client_id       = ""
  client_secret   = ""
  subscription_id = ""
  tenant_id       = ""

  location        = var.location
  os_type         = "Windows"
  public_ip_sku   = "Standard"

  image_publisher = "MicrosoftWindowsDesktop"
  image_offer     = "office-365"
  image_sku       = "win11-23h2-avd-m365"

  communicator = "winrm"
  winrm_use_ssl = true
  winrm_insecure = true
  winrm_timeout = "5m"
  winrm_username = "packer"
  winrm_password = "P@ckerPassword123!"

  managed_image_name                = "myPackerImage"
  managed_image_resource_group_name = var.image_resource_group_name

  shared_image_gallery_destination {
    resource_group      = "myPackerImages"
    gallery_name        = "myGallery"
    image_name          = "myWin11VDIImage"
    image_version       = "1.0.0"
    replication_regions = ["northeurope", "westeurope"]
  }

  vm_size = "Standard_D2s_v3"

  azure_tags = {
    dept = "Engineering"
    task = "Win11 VDI Image Build"
  }
}

build {
  sources = ["source.azure-arm.builder"]

  # Windows provisioner (PowerShell)
  provisioner "powershell" {
    inline = [
      "Write-Host 'Running Windows 11 VDI customization...'",
      "Set-ExecutionPolicy Bypass -Scope Process -Force",
      "Install-PackageProvider -Name NuGet -Force",
      "Install-Module -Name PSWindowsUpdate -Force",
      "Import-Module PSWindowsUpdate",
      "Get-WindowsUpdate -AcceptAll -Install -AutoReboot"
    ]
  }

  # Sysprep for Windows AVD
  provisioner "powershell" {
    inline = [
      "Write-Host 'Running Sysprep for Windows 11 VDI...'",
      "C:\\Windows\\System32\\Sysprep\\Sysprep.exe /generalize /oobe /shutdown /mode:vm"
    ]
  }
}
