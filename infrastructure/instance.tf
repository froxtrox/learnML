data "azurerm_client_config" "current" {}

locals {
  current_user_id = coalesce(var.msi_id, data.azurerm_client_config.current.object_id)
}

resource "azurerm_resource_group" "rg" {
  name     = coalesce(var.resource_group_name, "rg-${random_string.azurerm_key_vault_name.result}")
  location = var.location
}

resource "azurerm_application_insights" "workspaceai" {
  name                = coalesce(var.ai_name, "ai-${random_string.azurerm_key_vault_name.result}")
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
}

resource "random_string" "azurerm_key_vault_name" {
  length  = 13
  lower   = true
  numeric = false
  special = false
  upper   = false
}


resource "random_string" "azurerm_storage_account_suffix" {
  length  = 10
  lower   = true
  numeric = false
  special = false
  upper   = false
}


resource "azurerm_key_vault" "key_vault" {
  name                       = coalesce(var.vault_name, "vault-${random_string.azurerm_key_vault_name.result}")
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = var.sku_name
  soft_delete_retention_days = 90

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = local.current_user_id

    key_permissions    = var.key_permissions
    secret_permissions = var.secret_permissions
  }
}

resource "azurerm_storage_account" "storage_account" {
  name                     = coalesce(var.storage_account_name, "account${random_string.azurerm_storage_account_suffix.result}")
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

resource "azurerm_machine_learning_workspace" "workspace" {
  name                    = coalesce(var.workspace_name, "workspace-${random_string.azurerm_key_vault_name.result}")
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  application_insights_id = azurerm_application_insights.workspaceai.id
  key_vault_id            = azurerm_key_vault.key_vault.id
  storage_account_id      = azurerm_storage_account.storage_account.id

  identity {
    type = "SystemAssigned"
  }
}