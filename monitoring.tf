variable "alert_email" {
  description = "Adres odbiorcy alertów (demo)."
  type        = string
  default     = "student@example.com"
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-demo-${random_string.suffix.result}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  daily_quota_gb      = 0.5
  tags                = data.azurerm_resource_group.main.tags
}

resource "azurerm_application_insights" "main" {
  name                = "appi-demo-${random_string.suffix.result}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  tags                = data.azurerm_resource_group.main.tags
}

resource "azurerm_monitor_action_group" "main" {
  name                = "ag-demo"
  resource_group_name = data.azurerm_resource_group.main.name
  short_name          = "demo"
  tags                = data.azurerm_resource_group.main.tags

  email_receiver {
    name          = "student"
    email_address = var.alert_email
  }
}

resource "azurerm_monitor_activity_log_alert" "deletes" {
  name                = "alert-resource-delete"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = "global"
  scopes              = [data.azurerm_resource_group.main.id]
  description         = "Powiadomienie o usunięciu zasobu w RG."
  tags                = data.azurerm_resource_group.main.tags

  criteria {
    category       = "Administrative"
    operation_name = "Microsoft.Resources/subscriptions/resourceGroups/delete"
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}
