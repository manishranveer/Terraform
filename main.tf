resource "azurerm_resource_group" "iconnect_rg" {
  name     = var.resource_group_name
  location = var.location
}

# Key Vault
resource "azurerm_key_vault" "iconnect_kv" {
  name                        = "${var.project_name}kv"
  location                    = azurerm_resource_group.iconnect_rg.location
  resource_group_name         = azurerm_resource_group.iconnect_rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
}

# Cosmos DB Account
resource "azurerm_cosmosdb_account" "iconnect_cosmos" {
  name                = "${var.project_name}-cosmos"
  location            = azurerm_resource_group.iconnect_rg.location
  resource_group_name = azurerm_resource_group.iconnect_rg.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Session"
  }
}

# Storage Account
resource "azurerm_storage_account" "iconnect_storage" {
  name                     = "${var.project_name}store"
  resource_group_name      = azurerm_resource_group.iconnect_rg.name
  location                 = azurerm_resource_group.iconnect_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# CDN Profile
resource "azurerm_cdn_profile" "iconnect_cdn_profile" {
  name                = "${var.project_name}-cdn-profile"
  location            = azurerm_resource_group.iconnect_rg.location
  resource_group_name = azurerm_resource_group.iconnect_rg.name
  sku                 = "Standard_Microsoft"
}

# CDN Endpoint
resource "azurerm_cdn_endpoint" "iconnect_cdn_endpoint" {
  name                = "${var.project_name}-cdn-endpoint"
  profile_name        = azurerm_cdn_profile.iconnect_cdn_profile.name
  location            = azurerm_resource_group.iconnect_rg.location
  resource_group_name = azurerm_resource_group.iconnect_rg.name
  origin_host_header  = azurerm_storage_account.iconnect_storage.primary_blob_host
  is_http_allowed     = true
  is_https_allowed    = true

  origin {
    name      = "storageorigin"
    host_name = azurerm_storage_account.iconnect_storage.primary_blob_host
  }
}

# Needed for Key Vault tenant
data "azurerm_client_config" "current" {}
