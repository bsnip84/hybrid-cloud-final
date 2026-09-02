resource "azurerm_public_ip" "vpn" {
  name                = "pip-vpn-hybrid-dev"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "main" {
  name                = "vgw-hybrid-dev"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  type     = "Vpn"
  vpn_type = "RouteBased"
  sku      = "Basic"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id         = azurerm_public_ip.vpn.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                    = azurerm_subnet.gateway.id
  }
}
