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
  ]

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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_bunnynet"></a> [bunnynet](#requirement\_bunnynet) | 0.15.1 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_bunnynet"></a> [bunnynet](#provider\_bunnynet) | 0.15.1 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [bunnynet_dns_record.a](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.15.1/docs/resources/dns_record) | resource |
| [bunnynet_dns_record.cname](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.15.1/docs/resources/dns_record) | resource |
| [bunnynet_dns_record.mx](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.15.1/docs/resources/dns_record) | resource |
| [bunnynet_dns_record.txt](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.15.1/docs/resources/dns_record) | resource |
| [bunnynet_dns_zone.this](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.15.1/docs/resources/dns_zone) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_a_records"></a> [a\_records](#input\_a\_records) | A records to create. Use name = "" for the apex. Empty list creates none. | <pre>list(object({<br/>    name  = string<br/>    value = string<br/>    ttl   = optional(number)<br/>  }))</pre> | `[]` | no |
| <a name="input_cname_records"></a> [cname\_records](#input\_cname\_records) | CNAME records to create. Empty list creates none. | <pre>list(object({<br/>    name  = string<br/>    value = string<br/>    ttl   = optional(number)<br/>  }))</pre> | `[]` | no |
| <a name="input_dnssec_enabled"></a> [dnssec\_enabled](#input\_dnssec\_enabled) | Whether DNSSEC is enabled for the zone | `bool` | `true` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | Domain name for the Bunny.net DNS zone (e.g. example.com) | `string` | n/a | yes |
| <a name="input_mx_records"></a> [mx\_records](#input\_mx\_records) | MX records to create. Use name = "" for the apex. Empty list creates none. | <pre>list(object({<br/>    name     = string<br/>    value    = string<br/>    priority = number<br/>    ttl      = optional(number)<br/>  }))</pre> | `[]` | no |
| <a name="input_txt_records"></a> [txt\_records](#input\_txt\_records) | TXT records to create. Use name = "" for the apex. Empty list creates none. | <pre>list(object({<br/>    name  = string<br/>    value = string<br/>    ttl   = optional(number)<br/>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_a_record_ids"></a> [a\_record\_ids](#output\_a\_record\_ids) | Map of A record keys to Bunny.net record IDs |
| <a name="output_cname_record_ids"></a> [cname\_record\_ids](#output\_cname\_record\_ids) | Map of CNAME record keys to Bunny.net record IDs |
| <a name="output_domain"></a> [domain](#output\_domain) | Domain name of the DNS zone |
| <a name="output_mx_record_ids"></a> [mx\_record\_ids](#output\_mx\_record\_ids) | Map of MX record keys to Bunny.net record IDs |
| <a name="output_nameserver1"></a> [nameserver1](#output\_nameserver1) | Primary nameserver for the DNS zone |
| <a name="output_nameserver2"></a> [nameserver2](#output\_nameserver2) | Secondary nameserver for the DNS zone |
| <a name="output_txt_record_ids"></a> [txt\_record\_ids](#output\_txt\_record\_ids) | Map of TXT record keys to Bunny.net record IDs |
| <a name="output_zone_id"></a> [zone\_id](#output\_zone\_id) | Bunny.net DNS zone ID |
<!-- END_TF_DOCS -->
