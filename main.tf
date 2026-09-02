   terraform {
     required_providers {
       azurerm = {
         source  = "hashicorp/azurerm"
         version = "~> 4.0"
       }
     }
   }
provider "azurerm" {
  features {}
}
resource "azurerm_resource_group" "rg" {
  name     = "rg-hybrid-lab"
  location = "westeurope"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-hybrid-lab"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "workload" {
  name                 = "snet-workload"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
# --- Platform Services: Key Vault & ACR ---

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                       = "kvhybridlab12345"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"
    ]
  }
}

resource "azurerm_container_registry" "acr" {
  name                = "acrhybridlab12345"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}
# --- Workload: AKS Cluster ---

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-hybrid-lab"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "akshybridlab"
oidc_issuer_enabled = true
  default_node_pool {
    name           = "default"
    node_count     = var.aks_node_count
    vm_size        = var.aks_vm_size
    vnet_subnet_id = azurerm_subnet.workload.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "kubenet"
    service_cidr      = "172.16.0.0/16"
    dns_service_ip    = "172.16.0.10"
  }
} 
resource "azurerm_public_ip" "vpn_gw_ip" {
  name                = "pip-vpn-gateway"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones = ["1", "2", "3"]
}

resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.255.0/27"]
}
resource "azurerm_virtual_network_gateway" "Vpn_gw" {
  name                = "vgw-hybrid-lab"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  type     = "Vpn"
  vpn_type = "RouteBased"
  sku      = "VpnGw1AZ"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn_gw_ip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }
     
  vpn_client_configuration {
    address_space        = ["172.16.201.0/24"]
    vpn_client_protocols = ["OpenVPN"]

    root_certificate {
      name             = "P2SRootCert"
      public_cert_data = file("${path.module}/p2s-cert-base64.txt")
    }
  }
}