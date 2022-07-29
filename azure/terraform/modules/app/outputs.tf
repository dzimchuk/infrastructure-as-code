output "app_details" {
  value = {
    "resource_group_name" = azurerm_resource_group.resource_group.name
    "app_url" = azurerm_windows_web_app.test_app.default_hostname
  }
}