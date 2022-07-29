resource "azurerm_service_plan" "test_service_plan" {
  name                = join("-", [var.project_name, var.environment])
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  os_type             = "Windows"
  sku_name            = "B1"

  timeouts {
    create = "15m"
    delete = "15m"
  }
}

resource "azurerm_windows_web_app" "test_app" {
  name                       = join("-", [var.project_name, var.environment])
  location                   = azurerm_resource_group.resource_group.location
  resource_group_name        = azurerm_resource_group.resource_group.name
  service_plan_id            = azurerm_service_plan.test_service_plan.id

  app_settings = {
    TestVar                  = var.test_var
  }

  https_only = true

  site_config {
      always_on = true
      use_32_bit_worker = false
      application_stack {
        current_stack = "dotnet"
        dotnet_version = "v6.0"
      }
  }
  
  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = var.environment
  }

  depends_on = [
    azurerm_service_plan.test_service_plan
  ]
}
