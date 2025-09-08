# sanitize project name for resource-name composition
locals {
  project = lower(replace(var.project_name, "-", ""))
}

# client info for Key Vault access policy
data "azurerm_client_config" "current" {}

# Random suffix for unique naming
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# random suffixes for guaranteed unique names (hex strings)
resource "random_id" "suffix" {
  byte_length = 3   # 6 hex chars
}

resource "random_id" "kv_suffix" {
  byte_length = 2   # 4 hex chars
}

# Resource Group (unique)
resource "azurerm_resource_group" "rg" {
  name     = "${local.project}-rg-${random_id.suffix.hex}"
  location = var.location
  tags     = var.tags
}

# Storage Account (name must be 3-24 lowercase letters/numbers)
resource "azurerm_storage_account" "storage" {
  name                     = "${local.project}store${random_id.suffix.hex}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"
  tags                     = var.tags
}

# Key Vault (give current CLI principal access)
resource "azurerm_key_vault" "kv" {
  name                        = "iconnect-kv-${random_string.suffix.result}"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = false
  soft_delete_retention_days  = 7

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore",
      "Decrypt", "Encrypt", "UnwrapKey", "WrapKey", "Verify", "Sign", "Purge"
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"
    ]

    certificate_permissions = [
      "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore", "Purge"
    ]
  }
}


# Cosmos DB (SQL API / Core)
resource "azurerm_cosmosdb_account" "cosmos" {
  name                = "${local.project}cosmos${random_id.suffix.hex}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.rg.location
    failover_priority = 0
  }

  tags = var.tags
}
