locals {
  asset_map = {
    for pair in flatten([
      for zone in var.lake.zones : [
        for asset in zone.assets : {
          key        = "${zone.name}-${asset.name}"
          zone_name  = zone.name
          asset      = asset
        }
      ]
    ]) : pair.key => {
      zone_name = pair.zone_name
      asset     = pair.asset
    }
  }
  zone_iam_bindings = flatten([
    for zone in var.lake.zones : [
      for binding in lookup(zone.discovery_spec, "iam_bindings", []) : {
        zone_name = zone.name
        role      = binding.role
        members   = binding.members
      }
    ]
  ])
}

resource "google_dataplex_lake" "lake" {
  name         = var.lake.name
  display_name = var.lake.display_name
  description  = var.lake.description
  location     = var.metadata.region
  project      = var.metadata.project_id
  labels       = var.lake.labels[0]
}

resource "google_dataplex_lake_iam_binding" "lake_iam" {
  for_each = { for binding in var.lake.iam_bindings : binding.role => binding }

  project  = google_dataplex_lake.lake.project
  location = google_dataplex_lake.lake.location
  lake     = google_dataplex_lake.lake.name
  role     = each.value.role
  members  = each.value.members
}

resource "google_dataplex_zone" "zone" {
  for_each = {
    for zone in var.lake.zones : zone.name => zone
  }

  name         = each.value.name
  display_name = each.value.display_name
  type         = each.value.type
  location     = var.metadata.region
  project      = var.metadata.project_id
  lake         = google_dataplex_lake.lake.name
  labels       = each.value.labels[0]

  resource_spec {
    location_type = each.value.resource_spec.location_type
  }

  discovery_spec {
    enabled          = each.value.discovery_spec.enabled
    include_patterns = each.value.discovery_spec.include_patterns
    exclude_patterns = each.value.discovery_spec.exclude_patterns
    schedule         = each.value.discovery_spec.schedule
  }
}

resource "google_dataplex_zone_iam_binding" "zone_iam" {
  for_each = { for b in local.zone_iam_bindings : "${b.zone_name}-${b.role}" => b }

  project       = google_dataplex_zone.zone[each.value.zone_name].project
  location      = google_dataplex_zone.zone[each.value.zone_name].location
  lake          = google_dataplex_zone.zone[each.value.zone_name].lake
  dataplex_zone = google_dataplex_zone.zone[each.value.zone_name].name
  role          = each.value.role
  members       = each.value.members
}

resource "google_dataplex_asset" "asset" {
  for_each = local.asset_map

  name          = each.value.asset.name
  display_name  = each.value.asset.display_name
  location      = var.metadata.region
  project       = var.metadata.project_id
  lake          = google_dataplex_lake.lake.name
  dataplex_zone = google_dataplex_zone.zone[each.value.zone_name].name

  resource_spec {
    type = each.value.asset.resource_spec.type
    name = each.value.asset.resource_spec.name
  }

  discovery_spec {
    enabled          = each.value.asset.discovery_spec.enabled
    include_patterns = each.value.asset.discovery_spec.include_patterns
    exclude_patterns = each.value.asset.discovery_spec.exclude_patterns
    schedule         = each.value.asset.discovery_spec.schedule
  }
}

