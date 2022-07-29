module "app" {
  source = "./modules/app"
  project_name = var.project_name
  environment = var.environment
  location = var.location
}

terraform {
  backend "azurerm" {
    resource_group_name  = "teststoragerg"
    storage_account_name = "andreitest"
    container_name       = "tfstate"
    key                  = "azuretf.env.tfstate"
  }
}