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
  description = <<-EOT
    A records to create. Use name = "" for the apex. Empty list creates none.
    Set cdn = true to enable Bunny CDN Acceleration for the hostname (creates a
    pull zone and issues a Let's Encrypt certificate for it). Bunny Shield is
    enabled by default when cdn = true; set shield = false to disable it.
  EOT
  type = list(object({
    name   = string
    value  = string
    ttl    = optional(number)
    cdn    = optional(bool, false)
    shield = optional(bool)
  }))
  default = []

  validation {
    condition     = alltrue([for r in var.a_records : r.shield != true || r.cdn])
    error_message = "a_records with shield = true also require cdn = true."
  }
}

variable "cname_records" {
  description = <<-EOT
    CNAME records to create. Use name = "" for the apex. Empty list creates none.
    Set cdn = true to enable Bunny CDN Acceleration for the hostname (creates a
    pull zone and issues a Let's Encrypt certificate for it). Bunny Shield is
    enabled by default when cdn = true; set shield = false to disable it.
  EOT
  type = list(object({
    name   = string
    value  = string
    ttl    = optional(number)
    cdn    = optional(bool, false)
    shield = optional(bool)
  }))
  default = []

  validation {
    condition     = alltrue([for r in var.cname_records : r.shield != true || r.cdn])
    error_message = "cname_records with shield = true also require cdn = true."
  }
}

variable "shield" {
  description = <<-EOT
    Defaults applied to Bunny Shield when CDN Acceleration is enabled for a
    record (unless that record sets shield = false).
    See https://bunny.net/docs/shield/ for plan tiers and options.
  EOT
  type = object({
    tier       = optional(string, "Basic")
    ddos_level = optional(string, "Medium")
    waf        = optional(bool, true)
    waf_mode   = optional(string, "Block")
  })
  default = {}

  validation {
    condition     = contains(["Basic", "Advanced", "Business", "Enterprise"], var.shield.tier)
    error_message = "shield.tier must be one of: Basic, Advanced, Business, Enterprise."
  }

  validation {
    condition     = contains(["Asleep", "Low", "Medium", "High", "Extreme"], var.shield.ddos_level)
    error_message = "shield.ddos_level must be one of: Asleep, Low, Medium, High, Extreme."
  }

  validation {
    condition     = contains(["Block", "Log"], var.shield.waf_mode)
    error_message = "shield.waf_mode must be one of: Block, Log."
  }
}

variable "pull_zones" {
  description = <<-EOT
    Explicit Bunny pull zones attached to this DNS zone. Distinct from record-level
    cdn = true (CDN Acceleration). Each entry creates a pull zone and, for every
    record_names entry, a CNAME pointing at the pull zone plus a matching pull zone
    hostname. Record names are relative to the zone: use "" for the apex and a
    leading "*." for wildcards (e.g. ["assets", "*.assets"]). Do not also list those
    names in a_records or cname_records.
    Set middleware to a Bunny compute script (type middleware) that rewrites origin
    requests. Shield/WAF is not enabled for these pull zones.
  EOT
  type = list(object({
    name         = string
    origin_url   = string
    record_names = list(string)
    # Bunny validates that live DNS already resolves to the pull zone before it will
    # attach a hostname or issue a certificate. Set false for the first apply so the
    # CNAMEs are created, then true once they have propagated.
    create_hostnames              = optional(bool, true)
    middleware                    = optional(string)
    tls                           = optional(bool, true)
    force_ssl                     = optional(bool, true)
    originshield_enabled          = optional(bool, false)
    originshield_zone             = optional(string)
    cache_expiration_time         = optional(number)
    cache_expiration_time_browser = optional(number)
    cache_vary                    = optional(list(string), [])
    cache_errors                  = optional(bool, false)
    # Serve stale content while the origin is unreachable and/or while Bunny is
    # refreshing the object. Empty disables stale serving.
    cache_stale = optional(list(string), [])
    # Optimize for large object delivery (cache slicing).
    cache_chunked = optional(bool, false)
    # Refresh expired objects in the background while continuing to serve the
    # cached response.
    use_background_update = optional(bool, false)
    # Collapse concurrent cache-MISS requests for the same URL into a single
    # origin fetch.
    request_coalescing_enabled = optional(bool, false)
    # Seconds to wait for a coalesced origin response before falling through.
    request_coalescing_timeout = optional(number)
  }))
  default = []

  validation {
    condition = alltrue([
      for z in var.pull_zones :
      startswith(z.origin_url, "http://") || startswith(z.origin_url, "https://")
    ])
    error_message = "pull_zones origin_url must start with http:// or https://."
  }

  validation {
    condition = alltrue([
      for z in var.pull_zones : alltrue([
        for v in z.cache_stale : contains(["offline", "updating"], v)
      ])
    ])
    error_message = "pull_zones cache_stale values must be offline and/or updating."
  }

  validation {
    condition = alltrue([
      for z in var.pull_zones :
      !z.originshield_enabled || contains(["FR", "IL"], coalesce(z.originshield_zone, ""))
    ])
    error_message = "pull_zones with originshield_enabled require originshield_zone FR or IL."
  }

  validation {
    condition     = alltrue([for z in var.pull_zones : length(trimspace(z.name)) > 0])
    error_message = "pull_zones name must be non-empty."
  }

  validation {
    condition     = length(distinct([for z in var.pull_zones : z.name])) == length(var.pull_zones)
    error_message = "pull_zones name values must be unique."
  }

  validation {
    condition     = alltrue([for z in var.pull_zones : length(z.record_names) > 0])
    error_message = "pull_zones record_names must contain at least one entry."
  }

  validation {
    condition     = length(distinct(flatten([for z in var.pull_zones : z.record_names]))) == length(flatten([for z in var.pull_zones : z.record_names]))
    error_message = "pull_zones record_names must be unique across all pull zones."
  }

  validation {
    condition = length(setintersection(
      toset([for r in var.cname_records : r.name]),
      toset(flatten([for z in var.pull_zones : z.record_names]))
    )) == 0
    error_message = "pull_zones record_names must not also appear in cname_records."
  }

  validation {
    condition = length(setintersection(
      toset([for r in var.a_records : r.name]),
      toset(flatten([for z in var.pull_zones : z.record_names]))
    )) == 0
    error_message = "pull_zones record_names must not also appear in a_records."
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
