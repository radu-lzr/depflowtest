required_providers {
  azurerm = ">= 4.60"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-terraform"
  location = "northeurope"
}

resource "azurerm_storage_account" "sa" {
  name                     = "stterraformradutest"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}