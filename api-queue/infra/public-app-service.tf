resource "azurerm_resource_group" "public_rg" {
  name = "rg-apiqueue-public-001"
  location = "northeurope"
}

resource "azurerm_service_plan" "public_apiplan" {
  name = "api-public-appplan"
  location = azurerm_resource_group.public_rg.location
  resource_group_name = azurerm_resource_group.public_rg.name
  os_type = "Linux"
  sku_name = "P1v2"
}

resource "azurerm_linux_web_app" "public_api" {
  name = "public-apiqueue"
  resource_group_name = azurerm_resource_group.public_rg.name
  location = azurerm_resource_group.public_rg.location
  service_plan_id = azurerm_service_plan.public_apiplan.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on = "true"
    container_registry_use_managed_identity = true
    health_check_path = "/healthz"

    application_stack {
      docker_image_name = "testapi:latest"
      docker_registry_url = "https://baloiseacrtestapps.azurecr.io" # azurerm_container_registry.acr.login_server
    }
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
  }
}

resource "azurerm_role_assignment" "public_api_rbac_acr" {
  principal_id = azurerm_linux_web_app.public_api.identity[0].principal_id
  scope = azurerm_container_registry.acr.id
  role_definition_name = "Contributor"
}