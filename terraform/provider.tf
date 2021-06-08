#Set the terraform required version
terraform {
  required_version = "~> 1.0.0"
  required_providers {
    # It is recommended to pin to a given version of the Provider
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.62.0"
    }

    random = {
      version = "~>2"
    }
  }
}

provider "azurerm" {
  features {}
}

# Data

# Make client_id, tenant_id, subscription_id and object_id variables
data "azurerm_client_config" "current" {}
