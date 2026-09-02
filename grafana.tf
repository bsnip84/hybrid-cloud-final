resource "azurerm_dashboard_grafana" "grafana" {
  name                              = "grafana-hybrid-lab"
  resource_group_name               = azurerm_resource_group.rg.name
  location                          = azurerm_resource_group.rg.location
  grafana_major_version             = "12"
  api_key_enabled                   = true
  deterministic_outbound_ip_enabled = false
  public_network_access_enabled     = true

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "grafana_monitoring_reader" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Monitoring Reader"
  principal_id         = azurerm_dashboard_grafana.grafana.identity[0].principal_id
}

output "grafana_endpoint" {
  value = azurerm_dashboard_grafana.grafana.endpoint
}
