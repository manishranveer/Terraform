resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_key_vault" "iconnect_kv" {
  name                        = "\${var.project_name}kv"
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = true
  soft_delete_retention_days  = 90
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault_access_policy" "owner" {
  key_vault_id = azurerm_key_vault.iconnect_kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = ["Get", "Set", "List"]
}

resource "azurerm_cosmosdb_account" "iconnect_cosmos" {
  name                = "\${var.project_name}-cosmos"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  capabilities {
    name = "EnableServerless"
  }
}

resource "azurerm_storage_account" "iconnect_storage" {
  name                     = "\${var.project_name}store"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_cdn_profile" "iconnect_cdn_profile" {
  name                = "\${var.project_name}-cdn-profile"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard_Microsoft"
}

resource "azurerm_cdn_endpoint" "iconnect_cdn_endpoint" {
  name                = "\${var.project_name}-cdn-endpoint"
  profile_name        = azurerm_cdn_profile.iconnect_cdn_profile.name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  origin_host_header  = azurerm_storage_account.iconnect_storage.primary_blob_host
  is_http_allowed     = true
  is_https_allowed    = true

  origin {
    name      = "blob-origin"
    host_name = azurerm_storage_account.iconnect_storage.primary_blob_host
  }
}
