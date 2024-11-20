module "naming" {
  source  = "cloudnationhq/naming/azure"
  version = "~> 0.22"

  suffix = ["demo", "dev"]
}

module "rg" {
  source  = "cloudnationhq/rg/azure"
  version = "~> 2.0"

  groups = {
    demo = {
      name     = module.naming.resource_group.name_unique
      location = "germanywestcentral"
    }
  }
}

module "network" {
  source  = "cloudnationhq/vnet/azure"
  version = "~> 8.0"

  naming = local.naming

  vnet = {
    name           = module.naming.virtual_network.name
    location       = module.rg.groups.demo.location
    resource_group = module.rg.groups.demo.name
    address_space  = ["10.19.0.0/16"]

    subnets = {
      sn1 = {
        network_security_group = {}
        address_prefixes       = ["10.19.1.0/24"]
      }
    }
  }
}

module "cosmosdb" {
  source  = "cloudnationhq/cosmosdb/azure"
  version = "~> 2.0"

  account = {
    name           = module.naming.cosmosdb_account.name_unique
    location       = module.rg.groups.demo.location
    resource_group = module.rg.groups.demo.name
    kind           = "MongoDB"
    capabilities   = ["EnableAggregationPipeline", "EnableMongo"]

    geo_location = {
      francecentral = {
        location          = "francecentral"
        failover_priority = 0
      }
    }
  }
}

module "private_dns" {
  source  = "cloudnationhq/pdns/azure"
  version = "~> 3.0"

  resource_group = module.rg.groups.demo.name

  zones = {
    private = {
      mongo = {
        name = "privatelink.mongo.cosmos.azure.com"
        virtual_network_links = {
          link1 = {
            virtual_network_id   = module.network.vnet.id
            registration_enabled = true
          }
        }
      }
    }
  }
}

module "privatelink" {
  source  = "cloudnationhq/pe/azure"
  version = "~> 1.0"

  resource_group = module.rg.groups.demo.name
  location       = module.rg.groups.demo.location

  endpoints = local.endpoints
}
