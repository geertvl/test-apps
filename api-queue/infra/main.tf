resource "azurerm_resource_group" "rg" {
  name = "rg-apiqueue-001"
  location = "northeurope"
}

resource "azurerm_container_registry" "acr" {
  name = "baloiseacrtestapps"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  sku = "Basic"
  admin_enabled = true

  public_network_access_enabled = true
}
