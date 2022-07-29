resource "azurerm_resource_group" "resource_group" {
  name      = join("-", [var.project_name, var.environment, "rg"])
  location  = var.location
}
