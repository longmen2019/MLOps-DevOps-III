data "terraform_remote_state" "cluster" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-etcd"
    storage_account_name = "tfstateacctlongmen"
    container_name       = "tfstate"
    key                  = "cluster/terraform.tfstate"
  }
}
