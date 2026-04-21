resource "azurerm_postgresql_flexible_server" "postgres" {
  name                   = "myapp-postgres-server"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location

  administrator_login    = "manoj"
  administrator_password = "Chawakula%400113"

  sku_name   = "B_Standard_B1ms"
  version    = "13"
  zone       = "1"

  storage_mb = 32768

  backup_retention_days = 7

  public_network_access_enabled = true
}

resource "azurerm_postgresql_flexible_server_database" "db" {
  name      = "employeedb"
  server_id = azurerm_postgresql_flexible_server.postgres.id
  collation = "en_US.utf8"
  charset   = "UTF8"
}

# Allow VM Public IP
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_vm" {
  name             = "allow-vm-ip"
  server_id        = azurerm_postgresql_flexible_server.postgres.id

  start_ip_address = azurerm_public_ip.pip.ip_address
  end_ip_address   = azurerm_public_ip.pip.ip_address
}

# Allow Azure Services
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure" {
  name             = "allow-azure"
  server_id        = azurerm_postgresql_flexible_server.postgres.id

  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Outputs
output "vm_public_ip" {
  value = azurerm_public_ip.pip.ip_address
}

output "postgres_fqdn" {
  value = azurerm_postgresql_flexible_server.postgres.fqdn
}