variable "domain" {
  description = "Domain name to register or manage (e.g. example.com). One domain per module instance."
  type        = string
}

variable "owner_contact_id" {
  description = <<-EOT
    Existing Scaleway contact ID for the domain owner.
    Takes precedence over owner_contact when both are set.
    At least one of owner_contact_id or owner_contact must be set.
  EOT
  type        = string
  nullable    = true
  default     = null
}

variable "owner_contact" {
  description = <<-EOT
    Owner contact details for the domain registration.
    Used when owner_contact_id is null.
    At least one of owner_contact_id or owner_contact must be set.
  EOT
  type = object({
    legal_form                  = string
    firstname                   = string
    lastname                    = string
    email                       = string
    phone_number                = string
    address_line_1              = string
    zip                         = string
    city                        = string
    country                     = string
    address_line_2              = optional(string)
    state                       = optional(string)
    company_name                = optional(string)
    email_alt                   = optional(string)
    fax_number                  = optional(string)
    vat_identification_code     = optional(string)
    company_identification_code = optional(string)
    lang                        = optional(string)
    whois_opt_in                = optional(bool)
    resale                      = optional(bool)
  })
  nullable = true
  default  = null

  validation {
    condition     = var.owner_contact_id != null || var.owner_contact != null
    error_message = "Set owner_contact_id and/or owner_contact (at least one is required; id takes precedence if both are set)."
  }
}

variable "duration_in_years" {
  description = "Registration period in years (used when purchasing a new domain)."
  type        = number
  default     = 1

  validation {
    condition     = var.duration_in_years >= 1
    error_message = "duration_in_years must be at least 1."
  }
}

variable "auto_renew" {
  description = "Whether to enable auto-renewal for the domain."
  type        = bool
  default     = true
}

variable "dnssec_enabled" {
  description = <<-EOT
    Whether to enable DNSSEC at the Scaleway registrar.
    When true, dnssec_ds_record must be set. When false, dnssec_ds_record must be null.
    Applied via the Scaleway registrar API because the Terraform provider cannot
    pass a custom DS payload.
  EOT
  type        = bool
  default     = false
}

variable "dnssec_ds_record" {
  description = <<-EOT
    DS record to publish at the Scaleway registrar when dnssec_enabled is true.
    Must be null when dnssec_enabled is false.
    algorithm and digest.type use Scaleway enum strings (e.g. ecdsap256sha256, sha_256).
  EOT
  type = object({
    key_id    = number
    algorithm = string
    digest = object({
      type   = string
      digest = string
    })
  })
  nullable = true
  default  = null

  validation {
    condition     = var.dnssec_enabled ? var.dnssec_ds_record != null : var.dnssec_ds_record == null
    error_message = "dnssec_ds_record must be set when dnssec_enabled is true, and must be null when dnssec_enabled is false."
  }
}

variable "project_id" {
  description = "Scaleway project ID. Defaults to the project configured on the provider."
  type        = string
  nullable    = true
  default     = null
}
