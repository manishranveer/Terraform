output "key_vault_uri" {
  value = azurerm_key_vault.iconnect_kv.vault_uri
}

output "cosmosdb_endpoint" {
  value = azurerm_cosmosdb_account.iconnect_cosmos.endpoint
}

output "storage_account_primary_endpoint" {
  value = azurerm_storage_account.iconnect_storage.primary_blob_endpoint
}

output "cdn_endpoint_url" {
  value = azurerm_cdn_endpoint.iconnect_cdn_endpoint.host_name
}
