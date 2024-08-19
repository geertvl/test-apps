resource "azurerm_resource_group" "rg" {
  name = "rg-apiqueue-001"
  location = "northeurope"
}

resource "azurerm_virtual_network" "vnet" {
  name = "api-queue-vnet"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  address_space = [ "10.0.0.0/22" ]
}

resource "azurerm_subnet" "appsnet" {
  name = "appsnet"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = [ "10.0.0.0/24" ]
  service_endpoints = [ "Microsoft.Storage" ]
}

resource "azurerm_subnet" "queuesnet" {
  name = "queuesnet"
  resource_group_name = azurerm_resource_group.rg.name
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
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location

  account_replication_type = "LRS"
  account_tier = "Standard"
}

resource "azurerm_private_endpoint" "storaccpep" {
  name = "api-queue-stor-pep"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
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
    resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "queuednslink" {
  name = "api-queue-dns-link"
  resource_group_name = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.queuednszone.name
  virtual_network_id = azurerm_virtual_network.vnet.id
}

resource "azurerm_container_registry" "acr" {
  name = "acr-test-apps"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  sku = "Basic"
  admin_enabled = true

  public_network_access_enabled = true
}