terraform {
  required_version = ">= 1.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  # Poświadczenia pochodzą z ARM_* (`source ~/.tf-training/studentNN.env`).
  # Providery zarejestrował prowadzący, a ta tożsamość nie ma do tego uprawnień.
  resource_provider_registrations = "none"

  features {}
}
