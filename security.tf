data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_user_assigned_identity" "app" {
  name                = "id-demo-app"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  tags                = data.azurerm_resource_group.main.tags
}

resource "azurerm_key_vault" "main" {
  name                       = "kv-demo-${random_string.suffix.result}"
  resource_group_name        = data.azurerm_resource_group.main.name
  location                   = var.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  rbac_authorization_enabled = false
  tags                       = data.azurerm_resource_group.main.tags

  # Uprawnienia danych przez access policy (Contributor nie może nadawać ról RBAC).
  access_policy {
    tenant_id          = data.azurerm_client_config.current.tenant_id
    object_id          = data.azurerm_client_config.current.object_id
    secret_permissions = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
  }

  access_policy {
    tenant_id          = data.azurerm_client_config.current.tenant_id
    object_id          = azurerm_user_assigned_identity.app.principal_id
    secret_permissions = ["Get", "List"]
  }
}

resource "random_password" "demo" {
  length  = 24
  special = false
}

resource "azurerm_key_vault_secret" "demo" {
  name         = "demo-password"
  value        = random_password.demo.result
  key_vault_id = azurerm_key_vault.main.id
}
