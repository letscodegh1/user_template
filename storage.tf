resource "azurerm_storage_account" "main" {
  # Nazwa globalnie unikalna: stały sufiks z ID grupy zasobów (bez dodatkowego providera).
  name                            = "st${substr(md5(data.azurerm_resource_group.main.id), 0, 10)}"
  resource_group_name             = data.azurerm_resource_group.main.name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  tags                            = data.azurerm_resource_group.main.tags
}

resource "azurerm_storage_container" "bucket" {
  name                  = "moj-bucket"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

output "storage_account_name" {
  value = azurerm_storage_account.main.name
}
