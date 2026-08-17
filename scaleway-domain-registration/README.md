# scaleway-domain-registration

OpenTofu module to manage a [Scaleway domain registration](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/domain_registration) (one domain per instance).

DNSSEC is not managed here: the provider cannot set a custom DS record, so `dnssec` is ignored after create (configure DNSSEC in the console/API if needed).

Optional `nameservers` updates the domain’s DNS zone delegation via the Scaleway DNS API (`scw dns record update-nameservers`, or curl). The registration resource itself cannot set nameservers.

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

### With external nameservers

```hcl
module "domain" {
  source = "github.com/grrywlsn/tofu-modules.git//scaleway-domain-registration?ref=scaleway-domain-registration-v1.0.0"

  domain           = "example.com"
  owner_contact_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

  nameservers = [
    "ns1.example-dns.net",
    "ns2.example-dns.net",
  ]
}
```

## Import

```bash
tofu import 'scaleway_domain_registration.this' '<project_id>/<task_id>'
```

Look up `task_id` with the [`scaleway_domain_registration` data source](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/data-sources/domain_registration) or the Scaleway API.

Note: changing the registrant after create requires a Scaleway domain trade (`TradeDomain`), not an in-place update. The module sets `lifecycle.ignore_changes` on `owner_contact` / `owner_contact_id` so config drift (e.g. after import) does not fail apply. Update contacts in the Scaleway console/API, then `tofu apply -refresh-only` to sync state.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
