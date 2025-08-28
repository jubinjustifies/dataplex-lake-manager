variable "environment" {
  type = string
}

variable "lake_folders" {
  type = list(string)
}

locals {
  # Load naming rules
  naming_rules = yamldecode(file("${path.module}/rule.yaml"))

  # Load all lake-mapping YAMLs
  lake_configs = flatten([
    for lake in var.lake_folders : yamldecode(
      file("${path.module}/configs/${var.environment}/${lake}/lake-mapping.yaml")
    )
  ])

  # Validate lake, zone, and asset names
  invalid_names = [
    for item in flatten([
      for config in local.lake_configs : [
        for lake in try(config.lakes, []) : [
          # Lake validation
          (can(regex(local.naming_rules.naming_conventions.lake.pattern, lake.name)) ? null : "Invalid lake name: ${lake.name} | Name validation rule failed"),

          # Zone validation
          [
            for zone in try(lake.zones, []) :
            (can(regex(local.naming_rules.naming_conventions.zone.pattern, zone.name)) ? null : "Invalid zone name: ${zone.name} | Name validation rule failed")
          ],

          # Asset validation
          [
            for zone in try(lake.zones, []) : [
              for asset in try(zone.assets, []) :
              (can(regex(local.naming_rules.naming_conventions.asset.pattern, asset.name)) ? null : "Invalid asset name: ${asset.name} | Name validation rule failed")
            ]
          ]
        ]
      ]
    ]) : item if item != null
  ]
}

check "naming_conventions" {
  assert {
    condition     = length(local.invalid_names) == 0
    error_message = "One or more resource names are invalid:\n- ${join("\n- ", local.invalid_names)}"
  }
}


module "lakes" {
  for_each = {
    for config in local.lake_configs : config.lakes[0].name => config
  }

  source = "./modules/lake_module"

  metadata = {
    project_id  = each.value.metadata.project_id
    region      = each.value.metadata.region
    environment = each.value.metadata.environment
  }

  lake = each.value.lakes[0]
}
