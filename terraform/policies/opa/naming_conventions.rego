package naming

lake_pattern := "^.+-lake$"
zone_pattern := "^.+-(raw|curated|consumption|restricted|experimentation)-zone$"
asset_pattern := ""

deny[msg] if {
  lake := input.lakes[_]
  not regex.match(lake_pattern, lake.name)
  msg := sprintf("Invalid lake name: %v", [lake.name])
}

deny[msg] if {
  lake := input.lakes[_]
  zone := lake.zones[_]
  not regex.match(zone_pattern, zone.name)
  msg := sprintf("Invalid zone name: %v", [zone.name])
}

deny[msg] if {
  lake := input.lakes[_]
  zone := lake.zones[_]
  asset := zone.assets[_]
  not regex.match(asset_pattern, asset.name)
  msg := sprintf("Invalid asset name: %v", [asset.name])
}
