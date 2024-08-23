resource "azurerm_resource_group" "private_rg" {
  name = "rg-apiqueue-private-001"
  location = "northeurope"
}

resource "azurerm_virtual_network" "vnet" {
  name = "api-queue-vnet"
  location = azurerm_resource_group.private_rg.location
  resource_group_name = azurerm_resource_group.private_rg.name

  address_space = [ "10.0.0.0/22" ]
}

resource "azurerm_subnet" "appsnet" {
  name = "appsnet"
  resource_group_name = azurerm_resource_group.private_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = [ "10.0.0.0/24" ]
  service_endpoints = [ "Microsoft.Storage" ]

  delegation {
    name = "webapp-delegation"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}

resource "azurerm_subnet" "queuesnet" {
  name = "queuesnet"
  resource_group_name = azurerm_resource_group.private_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = [ "10.0.1.0/24" ]

#   delegation {
#     name = "queue-delegation"
#     service_delegation {
#       name = "Microsoft.Network/azurePrivateLinkService"
#       actions = [ 
#         "Microsoft.Network/virtualNetworks/subnets/join/action"
#       ]
#     }
#   }
}

resource "azurerm_storage_account" "storacc" {
  name = "apiqueuestor"
  resource_group_name = azurerm_resource_group.private_rg.name
  location = azurerm_resource_group.rg.location

  account_replication_type = "LRS"
  account_tier = "Standard"
}

resource "azurerm_private_endpoint" "storaccpep" {
  name = "api-queue-stor-pep"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.private_rg.name
  subnet_id = azurerm_subnet.queuesnet.id

  private_service_connection {
    name = "api-queue-stor-privatelink"
    private_connection_resource_id = azurerm_storage_account.storacc.id
    is_manual_connection = false
    subresource_names = [ "queue" ]
  }
}

resource "azurerm_private_dns_zone" "queuednszone" {
    name = "privatelink.queue.core.windows.net"
    resource_group_name = azurerm_resource_group.private_rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "queuednslink" {
  name = "api-queue-dns-link"
  resource_group_name = azurerm_resource_group.private_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.queuednszone.name
  virtual_network_id = azurerm_virtual_network.vnet.id
}

resource "azurerm_service_plan" "apiplan" {
  name = "api-private-appplan"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.private_rg.name
  os_type = "Linux"
  sku_name = "P1v2"
}

resource "azurerm_linux_web_app" "api" {
  name = "private-apiqueue"
  resource_group_name = azurerm_resource_group.private_rg.name
  location = azurerm_resource_group.rg.location
  service_plan_id = azurerm_service_plan.apiplan.id

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

  virtual_network_subnet_id = azurerm_subnet.appsnet.id
}

resource "azurerm_role_assignment" "rolass1" {
  principal_id = azurerm_linux_web_app.api.identity[0].principal_id
  role_definition_name = "Storage Blob Data Contributor"
  scope = azurerm_resource_group.private_rg.id
}

resource "azurerm_role_assignment" "rolass2" {
  principal_id = azurerm_linux_web_app.api.identity[0].principal_id
  scope = azurerm_container_registry.acr.id
  role_definition_name = "Contributor"
}