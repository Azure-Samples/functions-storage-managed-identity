##################################################################################
# Main Terraform file 
##################################################################################

##################################################################################
# RESOURCES
##################################################################################

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    sample = "functions-storage-managed-identity"
  }
}

##################################################################################
# Storage Account
##################################################################################
resource "azurerm_storage_account" "storage_account" {
  name                     = var.basename
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  location = var.location
  tags = {
    sample = "functions-storage-managed-identity"
  }
}

resource "azurerm_storage_container" "storage_containers" {
  name                  = "sample"
  storage_account_name  = azurerm_storage_account.storage_account.name
  container_access_type = "private"
}

##################################################################################
# Function App
##################################################################################
resource "azurerm_application_insights" "logging" {
  name                = "${var.basename}-ai"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  application_type    = "web"
  tags = {
    sample = "functions-storage-managed-identity"
  }
}

resource "azurerm_storage_account" "fxnstor" {
  name                     = "${var.basename}fx"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  tags = {
    sample = "functions-storage-managed-identity"
  }
}

resource "azurerm_app_service_plan" "fxnapp" {
  name                = "${var.basename}-plan"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "functionapp"
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
  tags = {
    sample = "functions-storage-managed-identity"
  }
}

resource "azurerm_function_app" "fxn" {
  name                      = var.basename
  location                  = var.location
  resource_group_name       = var.resource_group_name
  app_service_plan_id       = azurerm_app_service_plan.fxnapp.id
  storage_connection_string = azurerm_storage_account.fxnstor.primary_connection_string
  version                   = "~3"
  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
      app_settings
    ]
  }
  tags = {
    sample = "functions-storage-managed-identity"
  }
}

##################################################################################
# Role Assignments
##################################################################################
// https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage-blob-data-reader
// allows for blobServices/generateUserDelegationKey and blobs/read
resource "azurerm_role_assignment" "functionToStorage1" {
  scope                = azurerm_storage_account.storage_account.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_function_app.fxn.identity[0].principal_id
}

// https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage-account-key-operator-service-role
// allows for listkeys/action and regeneratekey/action
resource "azurerm_role_assignment" "functionToStorage2" {
  scope                = azurerm_storage_account.storage_account.id
  role_definition_name = "Storage Account Key Operator Service Role"
  principal_id         = azurerm_function_app.fxn.identity[0].principal_id
}

// https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#reader-and-data-access
// allows for storageAccounts/read
resource "azurerm_role_assignment" "functionToStorage3" {
  scope                = azurerm_storage_account.storage_account.id
  role_definition_name = "Reader and Data Access"
  principal_id         = azurerm_function_app.fxn.identity[0].principal_id
}

##################################################################################
# Outputs
##################################################################################

resource "local_file" "app_deployment_script" {
  content  = <<CONTENT
#!/bin/bash

az functionapp config appsettings set -n ${azurerm_function_app.fxn.name} -g ${azurerm_resource_group.rg.name} --settings "APPINSIGHTS_INSTRUMENTATIONKEY=""${azurerm_application_insights.logging.instrumentation_key}""" > /dev/null
cd ../src ; func azure functionapp publish ${azurerm_function_app.fxn.name} --csharp ; cd ../terraform
CONTENT
  filename = "./deploy_app.sh"
}
