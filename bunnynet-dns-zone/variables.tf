variable "domain" {
  description = "Domain name for the Bunny.net DNS zone (e.g. example.com)"
  type        = string
}

variable "dnssec_enabled" {
  description = "Whether DNSSEC is enabled for the zone"
  type        = bool
  default     = true
}

variable "a_records" {
  description = "A records to create. Use name = \"\" for the apex. Empty list creates none."
  type = list(object({
    name  = string
    value = string
    ttl   = optional(number)
  }))
  default = []
}

variable "cname_records" {
  description = "CNAME records to create. Use name = \"\" for the apex. Empty list creates none."
  type = list(object({
    name  = string
    value = string
    ttl   = optional(number)
  }))
  default = []
}

variable "storage_zones" {
  description = <<-EOT
    Map of Bunny Storage zones keyed by the storage-zone name. Each entry
    creates a storage zone the pull zones can use as origin. Edge tier
    requires region = "DE". Replication regions cannot be removed later
    without recreating the zone.
  EOT
  type = map(object({
    region               = string
    zone_tier            = optional(string, "Standard")
    replication_regions  = optional(set(string), [])
    custom_404_file_path = optional(string)
    rewrite_404_to_200   = optional(bool, false)
  }))
  default = {}

  validation {
    condition     = alltrue([for name, _ in var.storage_zones : length(trimspace(name)) >= 4 && length(name) <= 64])
    error_message = "storage_zones keys (storage zone names) must be between 4 and 64 characters."
  }

  validation {
    condition = alltrue([
      for z in var.storage_zones :
      contains(["Standard", "Edge"], z.zone_tier)
    ])
    error_message = "storage_zones zone_tier must be Standard or Edge."
  }

  validation {
    condition = alltrue([
      for z in var.storage_zones :
      length(trimspace(z.region)) > 0 && (z.zone_tier != "Edge" || z.region == "DE")
    ])
    error_message = "storage_zones region must be set, and Edge-tier zones must use region DE."
  }
}

variable "pullzone_records" {
  description = <<-EOT
    Map of Bunny pull zones keyed by the desired pull-zone name. Each entry
    creates one pull zone shared by every hostname in hostnames.
    hostnames are relative to the zone: "" is the apex, "*" is a wildcard,
    "cdn" is cdn.<domain>, "*.cdn" is *.cdn.<domain>. For each hostname the
    module creates a CNAME to <name>.<cdn_domain> and attaches it as a TLS
    hostname on the pull zone.
    Do not also list those names in a_records or cname_records.
    Set exactly one of origin_url or storage_zone. origin_url must be https://
    unless origin_http = true (then http://). storage_zone is a key from
    storage_zones. Bunny takes TLS SNI from the origin_url hostname, not the
    public hostname.
    Omit shield for Basic Shield on; set shield = { enabled = false } to skip it.
  EOT
  type = map(object({
    hostnames    = list(string)
    origin_url   = optional(string)
    storage_zone = optional(string)
    origin_http  = optional(bool, false)
    middleware   = optional(string)
    tls          = optional(bool, true)
    force_ssl    = optional(bool, true)
    # Send the client's Host header to the origin instead of the origin hostname.
    forward_host_header           = optional(bool, true)
    verify_ssl                    = optional(bool, true)
    originshield_enabled          = optional(bool, false)
    originshield_zone             = optional(string)
    cache_expiration_time         = optional(number, 31919000)
    cache_expiration_time_browser = optional(number)
    cache_vary                    = optional(list(string), [])
    cache_errors                  = optional(bool, false)
    strip_cookies                 = optional(bool, false)
    block_no_referer              = optional(bool, false)
    # Bunny Smart Cache: only cache known-static extensions and MIME types.
    smart_cache   = optional(bool, true)
    cache_stale   = optional(list(string), [])
    cache_chunked = optional(bool, false)
    # Omit unless enabling; Bunny requires true (or unset) when cache_stale includes updating.
    use_background_update      = optional(bool)
    request_coalescing_enabled = optional(bool, false)
    request_coalescing_timeout = optional(number, 30)
    ttl                        = optional(number, 86400)
    # Omit for Basic Shield on. enabled defaults true when the object is set.
    shield = optional(object({
      enabled    = optional(bool, true)
      tier       = optional(string, "Basic")
      ddos_level = optional(string, "Medium")
      waf        = optional(bool, true)
      waf_mode   = optional(string, "Log")
    }))
    edge_rules = optional(list(object({
      description = optional(string, "")
      enabled     = optional(bool, true)
      match_type  = optional(string, "MatchAny")
      priority    = number
      actions = list(object({
        type       = string
        parameter1 = optional(string)
        parameter2 = optional(string)
        parameter3 = optional(string)
      }))
      triggers = list(object({
        type       = string
        match_type = optional(string, "MatchAny")
        patterns   = list(string)
        parameter1 = optional(string)
        parameter2 = optional(string)
      }))
    })), [])
  }))
  default = {}

  validation {
    condition     = alltrue([for name, _ in var.pullzone_records : length(trimspace(name)) > 0 && length(name) <= 40])
    error_message = "pullzone_records keys (pull zone names) must be non-empty and at most 40 characters."
  }

  validation {
    condition     = alltrue([for z in var.pullzone_records : length(z.hostnames) > 0])
    error_message = "pullzone_records hostnames must contain at least one entry."
  }

  validation {
    condition     = length(distinct(flatten([for z in var.pullzone_records : z.hostnames]))) == length(flatten([for z in var.pullzone_records : z.hostnames]))
    error_message = "pullzone_records hostnames must be unique across all pull zones."
  }

  validation {
    condition = length(setintersection(
      toset([for r in var.cname_records : r.name]),
      toset(flatten([for z in var.pullzone_records : z.hostnames]))
    )) == 0
    error_message = "pullzone_records hostnames must not also appear in cname_records."
  }

  validation {
    condition = length(setintersection(
      toset([for r in var.a_records : r.name]),
      toset(flatten([for z in var.pullzone_records : z.hostnames]))
    )) == 0
    error_message = "pullzone_records hostnames must not also appear in a_records."
  }

  validation {
    condition = alltrue([
      for z in var.pullzone_records :
      (z.origin_url != null && z.storage_zone == null) || (z.origin_url == null && z.storage_zone != null)
    ])
    error_message = "pullzone_records entries must set exactly one of origin_url or storage_zone."
  }

  validation {
    condition = alltrue([
      for z in var.pullzone_records :
      z.storage_zone == null || contains(keys(var.storage_zones), z.storage_zone)
    ])
    error_message = "pullzone_records storage_zone must match a key in storage_zones."
  }

  validation {
    condition = alltrue([
      for z in var.pullzone_records :
      !z.origin_http || z.origin_url != null
    ])
    error_message = "pullzone_records origin_http is only valid with origin_url."
  }

  validation {
    condition = alltrue([
      for z in var.pullzone_records :
      z.origin_url == null || (
        z.origin_http ? startswith(z.origin_url, "http://") : startswith(z.origin_url, "https://")
      )
    ])
    error_message = "pullzone_records origin_url must start with https:// unless origin_http = true (then http://)."
  }

  validation {
    condition     = alltrue([for z in var.pullzone_records : z.ttl > 0])
    error_message = "pullzone_records ttl must be a positive number of seconds."
  }

  validation {
    condition = alltrue([
      for z in var.pullzone_records : alltrue([
        for v in z.cache_stale : contains(["offline", "updating"], v)
      ])
    ])
    error_message = "pullzone_records cache_stale values must be offline and/or updating."
  }

  validation {
    condition = alltrue([
      for z in var.pullzone_records :
      !z.originshield_enabled || contains(["FR", "IL"], coalesce(z.originshield_zone, ""))
    ])
    error_message = "pullzone_records with originshield_enabled require originshield_zone FR or IL."
  }

  validation {
    condition = alltrue([
      for z in var.pullzone_records : alltrue([
        for rule in z.edge_rules :
        contains(["MatchAll", "MatchAny", "MatchNone"], rule.match_type)
      ])
    ])
    error_message = "pullzone_records edge_rules match_type must be MatchAll, MatchAny, or MatchNone."
  }

  validation {
    condition = alltrue([
      for z in var.pullzone_records : alltrue([
        for rule in z.edge_rules :
        length(rule.actions) > 0 && length(rule.triggers) > 0
      ])
    ])
    error_message = "pullzone_records edge_rules entries require at least one action and one trigger."
  }

  validation {
    condition = alltrue([
      for z in var.pullzone_records : alltrue([
        for rule in z.edge_rules :
        length(rule.triggers) == 1 || alltrue([
          for t in rule.triggers : length(t.patterns) <= 5
        ])
      ])
    ])
    error_message = "pullzone_records edge_rules with multiple triggers must have ≤5 patterns per trigger (single-trigger rules are auto-chunked)."
  }

  validation {
    condition = alltrue([
      for z in var.pullzone_records :
      z.shield == null || contains(["Basic", "Advanced", "Business", "Enterprise"], z.shield.tier)
    ])
    error_message = "pullzone_records shield.tier must be one of: Basic, Advanced, Business, Enterprise."
  }

  validation {
    condition = alltrue([
      for z in var.pullzone_records :
      z.shield == null || contains(["Asleep", "Low", "Medium", "High", "Extreme"], z.shield.ddos_level)
    ])
    error_message = "pullzone_records shield.ddos_level must be one of: Asleep, Low, Medium, High, Extreme."
  }

  validation {
    condition = alltrue([
      for z in var.pullzone_records :
      z.shield == null || contains(["Block", "Log"], z.shield.waf_mode)
    ])
    error_message = "pullzone_records shield.waf_mode must be one of: Block, Log."
  }
}

variable "txt_records" {
  description = "TXT records to create. Use name = \"\" for the apex. Empty list creates none."
  type = list(object({
    name  = string
    value = string
    ttl   = optional(number)
  }))
  default = []
}

variable "mx_records" {
  description = "MX records to create. Use name = \"\" for the apex. Empty list creates none."
  type = list(object({
    name     = string
    value    = string
    priority = number
    ttl      = optional(number)
  }))
  default = []

  validation {
    condition     = alltrue([for r in var.mx_records : r.priority >= 0])
    error_message = "mx_records priority must be greater than or equal to 0."
  }
}
