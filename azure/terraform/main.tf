module "app" {
  source = "./modules/app"
  project_name = var.project_name
  environment = var.environment
  location = var.location
}

terraform {
  backend "azurerm" {
    resource_group_name  = var.state_resource_group_name
    storage_account_name = var.state_storage_account_name
    container_name       = var.state_container_name
    key                  = "azuretf.${var.environment}.tfstate"
  }
}