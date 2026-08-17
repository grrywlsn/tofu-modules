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
    ddos_mode  = optional(string, "Block")
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
    condition     = contains(["Block", "Log"], var.shield.ddos_mode)
    error_message = "shield.ddos_mode must be one of: Block, Log."
  }

  validation {
    condition     = contains(["Block", "Log"], var.shield.waf_mode)
    error_message = "shield.waf_mode must be one of: Block, Log."
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
