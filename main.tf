terraform {
  required_version = ">= 0.12"
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformfstate000"
    container_name       = "tfstate"
    key                  = "challenge.tfstate"
  }
}

provider "azurerm" {
  version = ">= 2.0.0"
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
    #scm_type                 = "GitHub"
  }

  app_settings = {
    "WEBSITE_NODE_DEFAULT_VERSION" = "10.15.2"
    "ApiUrl"                       = "/api/v1"
    "ApiUrlShoppingCart"           = "/api/v1"
    "MongoConnectionString"        = azurerm_container_group.challenge2.fqdn
    "SqlConnectionString"          = "Server=tcp:challenge2sqlserver.database.windows.net,1433;Initial Catalog=productsdb;Persist Security Info=False;User ID=4dm1n157r470r;Password=4-v3ry-53cr37-p455w0rd;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    "productImagesUrl"             = "https://raw.githubusercontent.com/suuus/TailwindTraders-Backend/master/Deploy/tailwindtraders-images/product-detail"
    "Personalizer__ApiKey"         = ""
    "Personalizer__Endpoint"       = ""
  }
}

resource "azurerm_resource_group" "challenge2" {
  name     = "rg-terraform-on-azure-challenge2"
  location = "eastus"
}

resource "azurerm_sql_server" "challenge2" {
  name                         = "challenge2sqlserver"
  resource_group_name          = azurerm_resource_group.challenge2.name
  location                     = azurerm_resource_group.challenge2.location
  version                      = "12.0"
  administrator_login          = "4dm1n157r470r"
  administrator_login_password = "4-v3ry-53cr37-p455w0rd"
}

resource "azurerm_sql_database" "challenge2" {
  name                = "productsdb"
  resource_group_name = azurerm_resource_group.challenge2.name
  location            = azurerm_resource_group.challenge2.location
  server_name         = azurerm_sql_server.challenge2.name
}

resource "azurerm_container_group" "challenge2" {
  name                = "mongodb-continst"
  location            = azurerm_resource_group.challenge2.location
  resource_group_name = azurerm_resource_group.challenge2.name
  ip_address_type     = "public"
  dns_name_label      = "mongodb"
  os_type             = "Linux"

  container {
    name   = "mongodb"
    image  = "mongo:latest"
    cpu    = 1
    memory = 2

    ports {
      port     = 27017
      protocol = "TCP"
    }
  }
}
/*
resource "null_resource" "challenge2" {
  provisioner "local-exec" {
    command = "az webapp deployment source config --name ${azurerm_app_service.challenge1.name} --resource-group ${azurerm_resource_group.challenge1.name} --repo-url https://github.com/kuhlman-labs/AzureEats-Website --branch master --repository-type github --git-token ea6c454072a3c398e8c8ed802d0e14ef21c47852"
  }
}
*/

resource "azurerm_resource_group" "challenge4" {
  name     = "challenge4-resources"
  location = "eastus"
}

resource "azurerm_container_registry" "challenge4" {
  name                = "challenge4acrbrkuhlma"
  resource_group_name = azurerm_resource_group.challenge4.name
  location            = azurerm_resource_group.challenge4.location
  sku                 = "Standard"
}

resource "azurerm_kubernetes_cluster" "challenge4" {
  name                = "challenge4-aks1"
  location            = azurerm_resource_group.challenge4.location
  resource_group_name = azurerm_resource_group.challenge4.name
  dns_prefix          = "challenge4aks1"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_public_ip" "challenge5" {
  name                = "challenge5Ip1"
  resource_group_name = azurerm_kubernetes_cluster.challenge4.node_resource_group
  location            = azurerm_resource_group.challenge4.location
  allocation_method   = "Static"
}

provider "kubernetes" {
  load_config_file       = "false"
  host                   = azurerm_kubernetes_cluster.challenge4.kube_config.0.host
  username               = azurerm_kubernetes_cluster.challenge4.kube_config.0.username
  password               = azurerm_kubernetes_cluster.challenge4.kube_config.0.password
  client_certificate     = base64decode(azurerm_kubernetes_cluster.challenge4.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.challenge4.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.challenge4.kube_config.0.cluster_ca_certificate)
}

resource "kubernetes_service" "challenge5" {
  metadata {
    name = "consul-mesh-lb"
  }
  spec {
    selector = {
      app       = "consul"
      component = "mesh-gateway"
    }
    load_balancer_ip = azurerm_public_ip.challenge5.ip_address
    session_affinity = "ClientIP"
    port {
      port        = 8302
      target_port = 80
    }
    type = "LoadBalancer"
  }
}

provider "helm" {
  kubernetes {
    load_config_file       = false
    host                   = azurerm_kubernetes_cluster.challenge4.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.challenge4.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.challenge4.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.challenge4.kube_config.0.cluster_ca_certificate)
  }
}

resource "helm_release" "challenge5" {
  name       = "my-consul-release"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "consul"

  values = [
    "${file("values.yaml")}",
    "${file("consul-federation.yaml")}"
  ]
}
