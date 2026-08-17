# scaleway-domain-registration

OpenTofu module to manage a [Scaleway domain registration](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/domain_registration) (one domain per instance).

DNS and DNSSEC for the domain can be managed outside this module (external DNS, Scaleway console, etc.). The module does not reconcile DNSSEC: `dnssec` is ignored after create so manual registrar DNSSEC settings are left alone.

## Example

### With contact details

```hcl
module "domain" {
  source = "github.com/grrywlsn/tofu-modules.git//scaleway-domain-registration?ref=scaleway-domain-registration-v1.0.0"

  domain     = "example.com"
  auto_renew = true

  owner_contact = {
    legal_form     = "individual"
    firstname      = "Jane"
    lastname       = "Doe"
    email          = "jane@example.com"
    phone_number   = "+44.7700900000"
    address_line_1 = "1 Example Street"
    city           = "London"
    zip            = "E1 1AA"
    country        = "GB"
  }
}
```

### With an existing contact ID

```hcl
module "domain" {
  source = "github.com/grrywlsn/tofu-modules.git//scaleway-domain-registration?ref=scaleway-domain-registration-v1.0.0"

  domain           = "example.com"
  owner_contact_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```

If both `owner_contact_id` and `owner_contact` are set, the ID is used.

## Import

```bash
tofu import 'scaleway_domain_registration.this' '<project_id>/<task_id>'
```

Look up `task_id` with the [`scaleway_domain_registration` data source](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/data-sources/domain_registration) or the Scaleway API.

Note: changing the registrant after create requires a Scaleway domain trade (`TradeDomain`), not an in-place update. The module sets `lifecycle.ignore_changes` on `owner_contact` / `owner_contact_id` so config drift (e.g. after import) does not fail apply. Update contacts in the Scaleway console/API, then `tofu apply -refresh-only` to sync state.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_scaleway"></a> [scaleway](#requirement\_scaleway) | 2.81.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_scaleway"></a> [scaleway](#provider\_scaleway) | 2.81.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [scaleway_domain_registration.this](https://registry.terraform.io/providers/scaleway/scaleway/2.81.0/docs/resources/domain_registration) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_auto_renew"></a> [auto\_renew](#input\_auto\_renew) | Whether to enable auto-renewal for the domain. | `bool` | `true` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | Domain name to register or manage (e.g. example.com). One domain per module instance. | `string` | n/a | yes |
| <a name="input_duration_in_years"></a> [duration\_in\_years](#input\_duration\_in\_years) | Registration period in years (used when purchasing a new domain). | `number` | `1` | no |
| <a name="input_owner_contact"></a> [owner\_contact](#input\_owner\_contact) | Owner contact details for the domain registration.<br/>Used when owner\_contact\_id is null.<br/>At least one of owner\_contact\_id or owner\_contact must be set. | <pre>object({<br/>    legal_form                  = string<br/>    firstname                   = string<br/>    lastname                    = string<br/>    email                       = string<br/>    phone_number                = string<br/>    address_line_1              = string<br/>    zip                         = string<br/>    city                        = string<br/>    country                     = string<br/>    address_line_2              = optional(string)<br/>    state                       = optional(string)<br/>    company_name                = optional(string)<br/>    email_alt                   = optional(string)<br/>    fax_number                  = optional(string)<br/>    vat_identification_code     = optional(string)<br/>    company_identification_code = optional(string)<br/>    lang                        = optional(string)<br/>    whois_opt_in                = optional(bool)<br/>    resale                      = optional(bool)<br/>  })</pre> | `null` | no |
| <a name="input_owner_contact_id"></a> [owner\_contact\_id](#input\_owner\_contact\_id) | Existing Scaleway contact ID for the domain owner.<br/>Takes precedence over owner\_contact when both are set.<br/>At least one of owner\_contact\_id or owner\_contact must be set. | `string` | `null` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Scaleway project ID. Defaults to the project configured on the provider. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_administrative_contact"></a> [administrative\_contact](#output\_administrative\_contact) | Administrative contact details returned by Scaleway. |
| <a name="output_auto_renew"></a> [auto\_renew](#output\_auto\_renew) | Whether auto-renewal is enabled on the registration resource. |
| <a name="output_dnssec"></a> [dnssec](#output\_dnssec) | DNSSEC flag reported by the registration resource (not managed by this module). |
| <a name="output_domain"></a> [domain](#output\_domain) | Managed domain name. |
| <a name="output_ds_record"></a> [ds\_record](#output\_ds\_record) | DS record reported by the registration resource (not managed by this module). |
| <a name="output_id"></a> [id](#output\_id) | ID of the domain registration (project\_id/task\_id). |
| <a name="output_owner_contact"></a> [owner\_contact](#output\_owner\_contact) | Owner contact details on the registration. |
| <a name="output_owner_contact_id"></a> [owner\_contact\_id](#output\_owner\_contact\_id) | Owner contact ID assigned by Scaleway. |
| <a name="output_project_id"></a> [project\_id](#output\_project\_id) | Scaleway project ID of the registration. |
| <a name="output_task_id"></a> [task\_id](#output\_task\_id) | Task ID of the domain registration. |
| <a name="output_technical_contact"></a> [technical\_contact](#output\_technical\_contact) | Technical contact details returned by Scaleway. |
<!-- END_TF_DOCS -->
