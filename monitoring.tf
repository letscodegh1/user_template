variable "alert_email" {
  description = "Adres odbiorcy alertów (demo)."
  type        = string
  default     = "student@example.com"
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
