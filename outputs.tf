output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "Resource Group created"
}

output "storage_account_name" {
  value       = azurerm_storage_account.storage.name
  description = "Storage account name"
}

output "storage_primary_blob_endpoint" {
  value       = azurerm_storage_account.storage.primary_blob_endpoint
  description = "Storage primary blob endpoint"
}

output "key_vault_name" {
  value       = azurerm_key_vault.kv.name
  description = "Key Vault name"
}

output "key_vault_uri" {
  value       = azurerm_key_vault.kv.vault_uri
  description = "Key Vault URI"
}

output "cosmosdb_account_name" {
  value       = azurerm_cosmosdb_account.cosmos.name
  description = "Cosmos DB account name"
}

output "cosmosdb_endpoint" {
  value       = azurerm_cosmosdb_account.cosmos.endpoint
  description = "Cosmos DB endpoint"
}
