variable "metadata" {
  type = object({
    project_id  = string
    region      = string
    environment = string
  })
}

variable "lake" {
  type = object({
    name        = string
    display_name = string
    description = string
    labels      = list(map(string))
    iam_bindings = optional(list(object({
      role    = string
      members = list(string)
    })), [])
    zones = list(object({
      name         = string
      display_name = string
      type         = string
      labels       = list(map(string))
      resource_spec = object({
        location_type = string
      })
      discovery_spec = object({
        enabled          = bool
        include_patterns = list(string)
        exclude_patterns = list(string)
        schedule         = string
        iam_bindings = optional(list(object({
          role    = string
          members = list(string)
        })), [])
      })
      assets = list(object({
        name         = string
        display_name = string
        resource_spec = object({
          type = string
          name = string
        })
        discovery_spec = object({
          enabled          = bool
          include_patterns = list(string)
          exclude_patterns = list(string)
          schedule         = string
        })
      }))
    }))
  })
}
