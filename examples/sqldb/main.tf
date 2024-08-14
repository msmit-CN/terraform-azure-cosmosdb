module "naming" {
  source  = "cloudnationhq/naming/azure"
  version = "~> 0.1"

  suffix = ["demo", "prd"]
}

module "rg" {
  source  = "cloudnationhq/rg/azure"
  version = "~> 0.1"

  groups = {
    demo = {
      name   = module.naming.resource_group.name
      region = "germanywestcentral"
    }
  }
}

module "cosmosdb" {
  source  = "cloudnationhq/cosmosdb/azure"
  version = "~> 1.0"

  account = {
    name           = module.naming.cosmosdb_account.name
    location       = module.rg.groups.demo.location
    resource_group = module.rg.groups.demo.name
    kind           = "GlobalDocumentDB"

    geo_location = {
      francecentral = {
        location          = "francecentral"
        failover_priority = 0
      }
    }

    databases = {
      sql = {
        db1 = {
          throughput = 400
          containers = {
            sqlc1 = {
              throughput          = 400
              partition_key_paths = ["/definition/idlong"]
              index_policy = {
                indexing_mode  = "consistent"
                included_paths = ["/*"]
              }
              unique_key = {
                key1 = {
                  paths = ["/definition/idlong", "/definition/idshort"]
                }
                key2 = {
                  paths = ["/definition/type", "/definition/category"]
                }
              }
            }
          }
        }
      }
    }
  }
}
