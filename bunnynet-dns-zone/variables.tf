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
    Set cdn = true to create a Terraform-managed Bunny pull zone for the
    hostname (origin URL derived from the record value) and a PullZone DNS
    record that links them. Bunny Shield is enabled by default when cdn = true;
    set shield = false to disable it. CDN records inherit module cdn_edge_rules
    unless edge_rules is set on the record (including [] to attach none).
    Origin TLS is verified by default (verify_ssl = true).
  EOT
  type = list(object({
    name                       = string
    value                      = string
    ttl                        = optional(number)
    cdn                        = optional(bool, false)
    shield                     = optional(bool)
    origin_http                = optional(bool, false)
    forward_host_header        = optional(bool, true)
    verify_ssl                 = optional(bool, true)
    strip_cookies              = optional(bool, false)
    cache_vary                 = optional(list(string), [])
    cache_stale                = optional(list(string), [])
    cache_chunked              = optional(bool, false)
    use_background_update      = optional(bool, false)
    request_coalescing_enabled = optional(bool, false)
    request_coalescing_timeout = optional(number, 30)
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
    })))
  }))
  default = []

  validation {
    condition     = alltrue([for r in var.a_records : r.shield != true || r.cdn])
    error_message = "a_records with shield = true also require cdn = true."
  }

  validation {
    condition = alltrue([
      for r in var.a_records :
      r.edge_rules == null || r.cdn
    ])
    error_message = "a_records edge_rules requires cdn = true."
  }
}

variable "cname_records" {
  description = <<-EOT
    CNAME records to create. Use name = "" for the apex. Empty list creates none.
    Set cdn = true to create a Terraform-managed Bunny pull zone for the
    hostname (origin URL derived from the record value) and a PullZone DNS
    record that links them. Bunny Shield is enabled by default when cdn = true;
    set shield = false to disable it. CDN records inherit module cdn_edge_rules
    unless edge_rules is set on the record (including [] to attach none).
    Origin TLS is verified by default (verify_ssl = true).
  EOT
  type = list(object({
    name                       = string
    value                      = string
    ttl                        = optional(number)
    cdn                        = optional(bool, false)
    shield                     = optional(bool)
    origin_http                = optional(bool, false)
    forward_host_header        = optional(bool, true)
    verify_ssl                 = optional(bool, true)
    strip_cookies              = optional(bool, false)
    cache_vary                 = optional(list(string), [])
    cache_stale                = optional(list(string), [])
    cache_chunked              = optional(bool, false)
    use_background_update      = optional(bool, false)
    request_coalescing_enabled = optional(bool, false)
    request_coalescing_timeout = optional(number, 30)
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
    })))
  }))
  default = []

  validation {
    condition     = alltrue([for r in var.cname_records : r.shield != true || r.cdn])
    error_message = "cname_records with shield = true also require cdn = true."
  }

  validation {
    condition = alltrue([
      for r in var.cname_records :
      r.edge_rules == null || r.cdn
    ])
    error_message = "cname_records edge_rules requires cdn = true."
  }
}

variable "cdn_edge_rules" {
  description = <<-EOT
    Edge rules applied to every CDN (cdn = true) A/CNAME record that does not
    set its own edge_rules. Default is [] (no rules). Pass an explicit list from
    the caller to configure cache/bypass (or any other) Bunny edge rules. Lower
    priority numbers run first; OverrideCacheTime short-circuits on the first
    match, so put bypasses at lower priorities than cache rules.
    Bunny allows at most 5 patterns per trigger: a single-trigger rule with more
    than 5 patterns is split across consecutive priorities automatically.
  EOT
  type = list(object({
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
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.cdn_edge_rules :
      contains(["MatchAll", "MatchAny", "MatchNone"], rule.match_type)
    ])
    error_message = "cdn_edge_rules match_type must be MatchAll, MatchAny, or MatchNone."
  }

  validation {
    condition = alltrue([
      for rule in var.cdn_edge_rules :
      length(rule.actions) > 0 && length(rule.triggers) > 0
    ])
    error_message = "cdn_edge_rules entries require at least one action and one trigger."
  }

  validation {
    condition = alltrue([
      for rule in var.cdn_edge_rules :
      length(rule.triggers) == 1 || alltrue([
        for t in rule.triggers : length(t.patterns) <= 5
      ])
    ])
    error_message = "cdn_edge_rules with multiple triggers must have ≤5 patterns per trigger (single-trigger rules are auto-chunked)."
  }
}

variable "shield" {
  description = <<-EOT
    Defaults applied to Bunny Shield when a pull zone is created for a cdn = true
    record or a pull_zones entry with shield = true (unless that record sets
    shield = false).
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
    cdn = true. Each entry creates a pull zone and, for every record_names entry, a
    CNAME pointing at the pull zone plus a matching pull zone hostname. Record
    names are relative to the zone: use "" for the apex and a leading "*." for
    wildcards (e.g. ["assets", "*.assets"]). Do not also list those names in
    a_records or cname_records.
    Set middleware to a Bunny compute script (type middleware) that rewrites origin
    requests. origin_url must be https:// unless origin_http = true.
    Set forward_host_header = true when the origin routes by hostname; note that
    Bunny still uses the origin_url hostname for TLS SNI, so the origin needs a
    certificate and route for that name. Origin TLS is verified by default
    (verify_ssl = true). Set shield = true to apply the module-level shield
    defaults. These pull zones do not inherit cdn_edge_rules: pass edge_rules
    per pull zone.
  EOT
  type = list(object({
    name         = string
    origin_url   = string
    record_names = list(string)
    origin_http  = optional(bool, false)
    # Bunny validates that live DNS already resolves to the pull zone before it will
    # attach a hostname or issue a certificate. Set false for the first apply so the
    # CNAMEs are created, then true once they have propagated.
    create_hostnames = optional(bool, true)
    middleware       = optional(string)
    tls              = optional(bool, true)
    force_ssl        = optional(bool, true)
    # Send the client's Host header to the origin instead of the origin hostname.
    forward_host_header = optional(bool, false)
    # Verify the origin TLS certificate. Defaults to true.
    verify_ssl = optional(bool, true)
    # Bunny Shield, configured from the module-level shield input.
    shield                        = optional(bool, false)
    originshield_enabled          = optional(bool, false)
    originshield_zone             = optional(string)
    cache_expiration_time         = optional(number)
    cache_expiration_time_browser = optional(number)
    cache_vary                    = optional(list(string), [])
    cache_errors                  = optional(bool, false)
    # Bunny strips Set-Cookie from origin responses by default, which breaks any
    # origin that logs users in. Set false for application origins.
    strip_cookies = optional(bool, true)
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
    request_coalescing_timeout = optional(number, 30)
    # TTL in seconds for the CNAME records that point at this pull zone.
    ttl = optional(number, 86400)
    # Bunny edge rules for this pull zone. Same shape and chunking rules as
    # cdn_edge_rules, which explicit pull zones do not inherit.
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
  default = []

  validation {
    condition = alltrue([
      for z in var.pull_zones : alltrue([
        for rule in z.edge_rules :
        contains(["MatchAll", "MatchAny", "MatchNone"], rule.match_type)
      ])
    ])
    error_message = "pull_zones edge_rules match_type must be MatchAll, MatchAny, or MatchNone."
  }

  validation {
    condition = alltrue([
      for z in var.pull_zones : alltrue([
        for rule in z.edge_rules :
        length(rule.actions) > 0 && length(rule.triggers) > 0
      ])
    ])
    error_message = "pull_zones edge_rules entries require at least one action and one trigger."
  }

  validation {
    condition = alltrue([
      for z in var.pull_zones : alltrue([
        for rule in z.edge_rules :
        length(rule.triggers) == 1 || alltrue([
          for t in rule.triggers : length(t.patterns) <= 5
        ])
      ])
    ])
    error_message = "pull_zones edge_rules with multiple triggers must have ≤5 patterns per trigger (single-trigger rules are auto-chunked)."
  }

  validation {
    condition = alltrue([
      for z in var.pull_zones :
      z.origin_http ? startswith(z.origin_url, "http://") : startswith(z.origin_url, "https://")
    ])
    error_message = "pull_zones origin_url must start with https:// unless origin_http = true (then http://)."
  }

  validation {
    condition = alltrue([
      for z in var.pull_zones :
      z.ttl > 0
    ])
    error_message = "pull_zones ttl must be a positive number of seconds."
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
