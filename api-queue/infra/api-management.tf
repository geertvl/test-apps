resource "azurerm_resource_group" "rg_apim" {
    name = "rg-apimgmt-001"
    location = "northeurope"
}

resource "azurerm_api_management" "apim" {
    name = "api-queue-apim"
    location = azurerm_resource_group.rg_apim.location
    resource_group_name = azurerm_resource_group.rg_apim.name
    publisher_name = "BaloiseTest"
    publisher_email = "geert.van.laethem@devoteam.be"

    sku_name = "Developer_1"
}