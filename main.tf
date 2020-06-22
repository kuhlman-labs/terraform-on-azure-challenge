provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "challenge1" {
  name     = "rg-terraform-on-azure-challenge1"
  location = "eastus"
}

resource "azurerm_app_service_plan" "challenge1" {
  name                = "challenge1-appserviceplan"
  location            = azurerm_resource_group.challenge1.location
  resource_group_name = azurerm_resource_group.challenge1.name

  sku {
    tier = "Basic"
    size = "B1"
  }
}

resource "azurerm_app_service" "challenge1" {
  name                = "tf-on-azure-challenge1-bk"
  location            = azurerm_resource_group.challenge1.location
  resource_group_name = azurerm_resource_group.challenge1.name
  app_service_plan_id = azurerm_app_service_plan.challenge1.id

  site_config {
    dotnet_framework_version = "v4.0"
  }

  app_settings = {
    "WEBSITE_NODE_DEFAULT_VERSION" = "10.15.2"
    "ApiUrl"                       = ""
    "ApiUrlShoppingCart"           = ""
    "MongoConnectionString"        = ""
    "SqlConnectionString"          = ""
    "productImagesUrl"             = "https://raw.githubusercontent.com/microsoft/TailwindTraders-Backend/master/Deploy/tailwindtraders-images/product-detail"
    "Personalizer__ApiKey"         = ""
    "Personalizer__Endpoint"       = ""
  }
}