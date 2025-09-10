############################################
# MAIN.TF – Production-ready Terraform File
# Resources: Resource Group, Storage + Containers, SAS Token,
#            Key Vault, Cosmos DB
############################################

# -----------------------------
# Locals
# Used for sanitized project naming
# -----------------------------
locals {
  # Project name sanitized: lowercase, no hyphens
  project = lower(replace(var.project_name, "-", ""))
}

# -----------------------------
# Current Client Info (who runs Terraform)
# Used for Key Vault access policy
# -----------------------------
data "azurerm_client_config" "current" {}

# -----------------------------
# Random values for unique naming
# -----------------------------
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "random_id" "suffix" {
  byte_length = 3 # 6 hex chars
}

resource "random_id" "kv_suffix" {
  byte_length = 2 # 4 hex chars
}

# -----------------------------
# Resource Group
# -----------------------------
resource "azurerm_resource_group" "rg" {
  name     = "${local.project}-rg-${random_id.suffix.hex}"
  location = var.location
  tags     = var.tags
}

# -----------------------------
# Storage Account
# -----------------------------
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

# -----------------------------
# Storage Containers
# -----------------------------
resource "azurerm_storage_container" "media" {
  name                  = "media"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "profilepics" {
  name                  = "profilepics"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "messagecontent" {
  name                  = "messagecontent"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

# -----------------------------
# SAS Token for Blob Storage (Write Access Only)
# -----------------------------
data "azurerm_storage_account_sas" "write_sas" {
  connection_string = azurerm_storage_account.storage.primary_connection_string
  https_only        = true

  # Define which resource types can be accessed
  resource_types {
    service   = true
    container = true
    object    = true
  }

  # Only Blob service enabled
  services {
    blob  = true
    file  = false
    queue = false
    table = false
  }

  # Validity
  start  = formatdate("YYYY-MM-DD", timestamp())
  expiry = formatdate("YYYY-MM-DD", timeadd(timestamp(), "168h")) # 7 days

  # Permissions – write only
  permissions {
    read    = false
    write   = true
    delete  = false
    list    = false
    add     = false
    create  = false
    update  = false
    process = false
    tag     = false
    filter  = false
  }
}

# -----------------------------
# Key Vault
# -----------------------------
resource "azurerm_key_vault" "kv" {
  # Key Vault names are globally unique, so add random suffix
  name                        = "${local.project}kv${random_id.kv_suffix.hex}"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = false
  soft_delete_retention_days  = 7

  # Give current principal full access
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "List", "Update", "Create", "Import", "Delete",
      "Recover", "Backup", "Restore", "Decrypt", "Encrypt",
      "UnwrapKey", "WrapKey", "Verify", "Sign", "Purge"
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover",
      "Backup", "Restore", "Purge"
    ]

    certificate_permissions = [
      "Get", "List", "Update", "Create", "Import",
      "Delete", "Recover", "Backup", "Restore", "Purge"
    ]
  }
}

# -----------------------------
# Cosmos DB Account (SQL API)
# -----------------------------
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
}

# -----------------------------
# Cosmos DB SQL Database
# -----------------------------
resource "azurerm_cosmosdb_sql_database" "iconnectdb" {
  name                = "iconnectdb"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cosmos.name
}

# -----------------------------
# Cosmos DB SQL Container
# -----------------------------
resource "azurerm_cosmosdb_sql_container" "users" {
  name                = "Users"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cosmos.name
  database_name       = azurerm_cosmosdb_sql_database.iconnectdb.name
  partition_key_path  = "/userId"
  throughput          = 400

  indexing_policy {
    indexing_mode = "consistent"
  }
}



# -----------------------------
# Azure Container Registry (ACR)
# -----------------------------
resource "azurerm_container_registry" "acr" {
  name                = "${local.project}acr${random_id.suffix.hex}" # globally unique
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false
}

# -----------------------------
# Azure Kubernetes Service (AKS)
# -----------------------------
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${local.project}-aks-cluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${local.project}-aks"

  default_node_pool {
    name       = "systempool"
    node_count = 2
    vm_size    = "Standard_B2ms"
  }

  identity {
    type = "SystemAssigned"
  }

  # Enable RBAC (best practice)
  role_based_access_control_enabled = true
}

