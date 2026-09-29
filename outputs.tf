output "vnet_id" {
  value = azurerm_virtual_network.main.id
}

output "key_vault_name" {
  value = azurerm_key_vault.main.name
}

output "log_analytics_workspace" {
  value = azurerm_log_analytics_workspace.main.name
}
