locals {
  # owner_contact_id wins when both are provided (provider ExactlyOneOf).
  use_owner_contact_id = var.owner_contact_id != null
}

resource "scaleway_domain_registration" "this" {
  domain_names      = [var.domain]
  duration_in_years = var.duration_in_years
  auto_renew        = var.auto_renew
  # DNSSEC is managed outside this module (e.g. console); do not reconcile it.
  dnssec = false

  project_id = var.project_id

  owner_contact_id = local.use_owner_contact_id ? var.owner_contact_id : null

  dynamic "owner_contact" {
    for_each = local.use_owner_contact_id ? [] : [var.owner_contact]
    content {
      legal_form                  = owner_contact.value.legal_form
      firstname                   = owner_contact.value.firstname
      lastname                    = owner_contact.value.lastname
      email                       = owner_contact.value.email
      phone_number                = owner_contact.value.phone_number
      address_line_1              = owner_contact.value.address_line_1
      address_line_2              = owner_contact.value.address_line_2
      zip                         = owner_contact.value.zip
      city                        = owner_contact.value.city
      state                       = owner_contact.value.state
      country                     = owner_contact.value.country
      company_name                = owner_contact.value.company_name
      email_alt                   = owner_contact.value.email_alt
      fax_number                  = owner_contact.value.fax_number
      vat_identification_code     = owner_contact.value.vat_identification_code
      company_identification_code = owner_contact.value.company_identification_code
      lang                        = owner_contact.value.lang
      whois_opt_in                = owner_contact.value.whois_opt_in
      resale                      = owner_contact.value.resale
    }
  }

  # - Registrant changes need a Scaleway domain trade (TradeDomain).
  # - DNSSEC is intentionally ignored so it can be set manually without
  #   Terraform flipping it on every apply. Sync contacts with refresh-only if needed.
  lifecycle {
    ignore_changes = [
      owner_contact,
      owner_contact_id,
      dnssec,
    ]
  }
}
