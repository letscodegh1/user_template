resource "azurerm_private_dns_zone" "internal" {
  name                = "demo.internal"
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = data.azurerm_resource_group.main.tags
}
