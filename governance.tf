# ============================================
# Governance & Operations
# ============================================

# --- Recovery Services Vault (Backup) ---
resource "azurerm_recovery_services_vault" "rsv" {
  name                = "rsv-hybrid-lab"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  soft_delete_enabled = true
}

# --- Azure Policy: enforce allowed locations ---
resource "azurerm_resource_group_policy_assignment" "allowed_location" {
  name                 = "allowed-locations"
  resource_group_id    = azurerm_resource_group.rg.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"

  parameters = jsonencode({
    listOfAllowedLocations = {
      value = [var.location]
    }
  })
}

# --- Budget alert ---
resource "azurerm_consumption_budget_resource_group" "budget" {
  name              = "budget-hybrid-lab"
  resource_group_id = azurerm_resource_group.rg.id

  amount     = 50
  time_grain = "Monthly"

  time_period {
    start_date = "2026-08-01T00:00:00Z"
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    contact_emails = ["alnatourbelal120@gmail.com"]
  }
}