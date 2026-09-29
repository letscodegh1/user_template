
output "application_insights_connection_string" {
  description = "Connection string Application Insights (dla aplikacji)."
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

output "log_analytics_workspace_id" {
  description = "ID workspace Log Analytics."
  value       = azurerm_log_analytics_workspace.main.id
}
