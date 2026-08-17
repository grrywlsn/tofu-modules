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

variable "nameservers" {
  description = <<-EOT
    Authoritative nameservers to set on the Scaleway DNS zone for this domain
    (e.g. external DNS providers). Null means nameservers are not managed by
    this module. When set, must include at least two nameservers.
    The Terraform provider cannot set nameservers on scaleway_domain_registration;
    this module applies them via the Scaleway DNS API / scw CLI.
  EOT
  type        = list(string)
  nullable    = true
  default     = null

  validation {
    condition     = var.nameservers == null || length(var.nameservers) >= 2
    error_message = "nameservers must be null or a list of at least two nameserver hostnames."
  }
}

variable "project_id" {
  description = "Scaleway project ID. Defaults to the project configured on the provider."
  type        = string
  nullable    = true
  default     = null
}
