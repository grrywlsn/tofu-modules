# bunnynet-dns-zone

OpenTofu module to manage a [Bunny.net DNS zone](https://registry.terraform.io/providers/BunnyWay/bunnynet/latest/docs/resources/dns_zone) and lists of A, CNAME, TXT, and MX records.

## Example

```hcl
module "dns" {
  source = "github.com/grrywlsn/tofu-modules.git//bunnynet-dns-zone?ref=bunnynet-dns-zone-v1.0.0"

  domain = "example.com"

  a_records = [
    {
      name  = ""
      value = "192.0.2.10"
      # CDN Acceleration (+ Shield by default) + Let's Encrypt cert
      cdn = true
    },
    {
      name  = "www"
      value = "192.0.2.10"
      ttl   = 300
    },
  ]

  cname_records = [
    {
      name  = "cdn"
      value = "cdn.example.net"
    },
    {
      name   = "app"
      value  = "origin.example.net"
      cdn    = true
      shield = false # CDN without Bunny Shield
    },
  ]

  # Optional defaults for CDN-accelerated records (Shield on by default)
  # shield = {
  #   tier       = "Basic"
  #   ddos_level = "Medium"
  #   waf        = true
  #   waf_mode   = "Block"
  # }

  txt_records = [
    {
      name  = ""
      value = "v=spf1 include:_spf.example.com ~all"
    },
  ]

  mx_records = [
    {
      name     = ""
      value    = "mail.example.com"
      priority = 10
    },
  ]
}
```

Use `name = ""` for apex records. Record list variables default to `[]` (none).

Set `cdn = true` on an A or CNAME record to enable [CDN Acceleration](https://bunny.net/docs/cdn/cdn-acceleration): Bunny creates a pull zone for that hostname and issues a Let's Encrypt certificate. SSL only validates once the domain's nameservers point at Bunny DNS.

[Bunny Shield](https://bunny.net/docs/shield/) is enabled by default whenever `cdn = true`. Set `shield = false` on a record to skip it. Tune tier / DDoS / WAF via the module-level `shield` input (defaults: Basic, Medium, WAF on/Block).

## DNSSEC / Scaleway registrar

When `dnssec_enabled = true`, the module exposes:

- `dnssec_enabled` — whether DNSSEC is on for the zone
- `ds_record` — Scaleway-shaped DS object (`key_id`, `algorithm`, `digest`), or `null` until DS values are published

Wire into [`scaleway-domain-registration`](../scaleway-domain-registration):

```hcl
dependency "dns" {
  config_path = "../../../../bunny/dns-zones/example.com"
}

inputs = {
  dnssec_enabled   = dependency.dns.outputs.dnssec_enabled && dependency.dns.outputs.ds_record != null
  dnssec_ds_record = dependency.dns.outputs.ds_record
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_bunnynet"></a> [bunnynet](#requirement\_bunnynet) | 0.18.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_bunnynet"></a> [bunnynet](#provider\_bunnynet) | 0.18.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [bunnynet_dns_record.a](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.0/docs/resources/dns_record) | resource |
| [bunnynet_dns_record.cname](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.0/docs/resources/dns_record) | resource |
| [bunnynet_dns_record.mx](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.0/docs/resources/dns_record) | resource |
| [bunnynet_dns_record.txt](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.0/docs/resources/dns_record) | resource |
| [bunnynet_dns_zone.this](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.0/docs/resources/dns_zone) | resource |
| [bunnynet_pullzone_shield.a](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.0/docs/resources/pullzone_shield) | resource |
| [bunnynet_pullzone_shield.cname](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.0/docs/resources/pullzone_shield) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_a_records"></a> [a\_records](#input\_a\_records) | A records to create. Use name = "" for the apex. Empty list creates none.<br/>Set cdn = true to enable Bunny CDN Acceleration for the hostname (creates a<br/>pull zone and issues a Let's Encrypt certificate for it). Bunny Shield is<br/>enabled by default when cdn = true; set shield = false to disable it. | <pre>list(object({<br/>    name   = string<br/>    value  = string<br/>    ttl    = optional(number)<br/>    cdn    = optional(bool, false)<br/>    shield = optional(bool)<br/>  }))</pre> | `[]` | no |
| <a name="input_cname_records"></a> [cname\_records](#input\_cname\_records) | CNAME records to create. Use name = "" for the apex. Empty list creates none.<br/>Set cdn = true to enable Bunny CDN Acceleration for the hostname (creates a<br/>pull zone and issues a Let's Encrypt certificate for it). Bunny Shield is<br/>enabled by default when cdn = true; set shield = false to disable it. | <pre>list(object({<br/>    name   = string<br/>    value  = string<br/>    ttl    = optional(number)<br/>    cdn    = optional(bool, false)<br/>    shield = optional(bool)<br/>  }))</pre> | `[]` | no |
| <a name="input_dnssec_enabled"></a> [dnssec\_enabled](#input\_dnssec\_enabled) | Whether DNSSEC is enabled for the zone | `bool` | `true` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | Domain name for the Bunny.net DNS zone (e.g. example.com) | `string` | n/a | yes |
| <a name="input_mx_records"></a> [mx\_records](#input\_mx\_records) | MX records to create. Use name = "" for the apex. Empty list creates none. | <pre>list(object({<br/>    name     = string<br/>    value    = string<br/>    priority = number<br/>    ttl      = optional(number)<br/>  }))</pre> | `[]` | no |
| <a name="input_shield"></a> [shield](#input\_shield) | Defaults applied to Bunny Shield when CDN Acceleration is enabled for a<br/>record (unless that record sets shield = false).<br/>See https://bunny.net/docs/shield/ for plan tiers and options. | <pre>object({<br/>    tier       = optional(string, "Basic")<br/>    ddos_level = optional(string, "Medium")<br/>    waf        = optional(bool, true)<br/>    waf_mode   = optional(string, "Block")<br/>  })</pre> | `{}` | no |
| <a name="input_txt_records"></a> [txt\_records](#input\_txt\_records) | TXT records to create. Use name = "" for the apex. Empty list creates none. | <pre>list(object({<br/>    name  = string<br/>    value = string<br/>    ttl   = optional(number)<br/>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_a_cdn_pullzone_ids"></a> [a\_cdn\_pullzone\_ids](#output\_a\_cdn\_pullzone\_ids) | Map of A record keys with cdn = true to their Bunny CDN Acceleration pull zone IDs |
| <a name="output_a_record_ids"></a> [a\_record\_ids](#output\_a\_record\_ids) | Map of A record keys to Bunny.net record IDs |
| <a name="output_a_shield_ids"></a> [a\_shield\_ids](#output\_a\_shield\_ids) | Map of A record keys with Bunny Shield enabled to their Shield IDs |
| <a name="output_cname_cdn_pullzone_ids"></a> [cname\_cdn\_pullzone\_ids](#output\_cname\_cdn\_pullzone\_ids) | Map of CNAME record keys with cdn = true to their Bunny CDN Acceleration pull zone IDs |
| <a name="output_cname_record_ids"></a> [cname\_record\_ids](#output\_cname\_record\_ids) | Map of CNAME record keys to Bunny.net record IDs |
| <a name="output_cname_shield_ids"></a> [cname\_shield\_ids](#output\_cname\_shield\_ids) | Map of CNAME record keys with Bunny Shield enabled to their Shield IDs |
| <a name="output_dnssec_enabled"></a> [dnssec\_enabled](#output\_dnssec\_enabled) | Whether DNSSEC is enabled on the Bunny.net DNS zone |
| <a name="output_domain"></a> [domain](#output\_domain) | Domain name of the DNS zone |
| <a name="output_ds_record"></a> [ds\_record](#output\_ds\_record) | DS record shaped for scaleway-domain-registration's ds\_record input<br/>(key\_id / algorithm / digest). Null when DNSSEC is disabled or Bunny has<br/>not yet published DS values. |
| <a name="output_mx_record_ids"></a> [mx\_record\_ids](#output\_mx\_record\_ids) | Map of MX record keys to Bunny.net record IDs |
| <a name="output_nameserver1"></a> [nameserver1](#output\_nameserver1) | Primary nameserver for the DNS zone |
| <a name="output_nameserver2"></a> [nameserver2](#output\_nameserver2) | Secondary nameserver for the DNS zone |
| <a name="output_txt_record_ids"></a> [txt\_record\_ids](#output\_txt\_record\_ids) | Map of TXT record keys to Bunny.net record IDs |
| <a name="output_zone_id"></a> [zone\_id](#output\_zone\_id) | Bunny.net DNS zone ID |
<!-- END_TF_DOCS -->
