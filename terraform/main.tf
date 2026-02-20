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