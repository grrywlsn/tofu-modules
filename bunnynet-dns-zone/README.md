# bunnynet-dns-zone

OpenTofu module to manage a [Bunny.net DNS zone](https://registry.terraform.io/providers/BunnyWay/bunnynet/latest/docs/resources/dns_zone), literal A/CNAME/TXT/MX records, and [pull zones](https://registry.terraform.io/providers/BunnyWay/bunnynet/latest/docs/resources/pullzone).

Use `name = ""` for apex records. Record list variables default to `[]` (none). `pullzone_records` defaults to `{}`.

This is a **v3 breaking change**: `cdn = true` on A/CNAME records, `cdn_edge_rules`, the module-level `shield` input, and `pull_zones` are gone. Cache, Shield, and hostnames live only on `pullzone_records`.

## Examples

### Literal CNAME

```hcl
module "dns" {
  source = "github.com/grrywlsn/tofu-modules.git//bunnynet-dns-zone?ref=bunnynet-dns-zone-v3.0.0"

  domain = "example.com"

  cname_records = [
    {
      name  = "www"
      value = "origin.example.net"
      ttl   = 86400
    },
  ]
}
```

### Pull zone with Shield (defaults)

The map key is the Bunny pull-zone name. `hostnames` are relative to the zone (`""` apex, `"*"` wildcard). Each non-apex hostname gets a CNAME to `<name>.<cdn_domain>`. The apex uses Bunny's `PullZone` record type so it can coexist with TXT/MX. Every hostname is also attached on the pull zone so the edge can route by `Host`.

Defaults: HTTPS origin with verified TLS, public Host forwarded to origin, cookies preserved, [Smart Cache](https://bunny.net/docs/cdn/smart-cache) on, cache override 31919000 seconds, missing Referer allowed, hostname TLS + Force SSL, [Bunny Shield](https://bunny.net/docs/shield/) Basic on with WAF in Log mode.

```hcl
module "dns" {
  source = "github.com/grrywlsn/tofu-modules.git//bunnynet-dns-zone?ref=bunnynet-dns-zone-v3.0.0"

  domain = "example.com"

  pullzone_records = {
    "example-app" = {
      hostnames  = ["", "*"]
      origin_url = "https://origin.example.net"
    }
  }
}
```

Bunny takes TLS SNI from the `origin_url` hostname, not the public hostname. An origin that selects certificates by SNI needs a cert and route for that origin hostname (a hostname-less listener is the usual pattern).

Set `origin_http = true` and an `http://` origin for HTTP-only origins (for example an S3 website). Set `forward_host_header = false` if that origin expects its own hostname rather than the public `Host`.

### Storage zone origin (static site / SPA)

```hcl
module "dns" {
  source = "github.com/grrywlsn/tofu-modules.git//bunnynet-dns-zone?ref=bunnynet-dns-zone-v3.0.0"

  domain = "example.com"

  storage_zones = {
    "example-app" = {
      region               = "DE"
      replication_regions  = ["SE"]
      custom_404_file_path = "/index.html"
      rewrite_404_to_200   = true
    }
  }

  pullzone_records = {
    "example-app" = {
      hostnames    = [""]
      storage_zone = "example-app"
    }
  }
}
```

`storage_zone` must match a key in `storage_zones`. Use `/index.html` plus `rewrite_404_to_200` so client-side routes serve the SPA shell. Edge-tier zones must use `region = "DE"`. Replication regions cannot be removed later without recreating the zone.

### Shield off or custom

```hcl
pullzone_records = {
  "static-assets" = {
    hostnames  = ["cdn"]
    origin_url = "https://bucket.example.net"
    shield     = { enabled = false }
  }
  "app" = {
    hostnames  = [""]
    origin_url = "https://origin.example.net"
    shield     = { tier = "Advanced", waf_mode = "Block" }
  }
}
```

### Edge rules

Lower priority numbers run first. [`OverrideCacheTime` short-circuits](https://bunny.net/docs/cdn/edge-rules/ordering) on the first match, so put bypasses ahead of caching rules. Bunny caps a trigger at 5 patterns; a single-trigger rule with more than 5 is split across consecutive priorities automatically.

```hcl
pullzone_records = {
  "example-app" = {
    hostnames  = ["", "*"]
    origin_url = "https://origin.example.net"
    cache_vary = ["querystring", "hostname"]

    edge_rules = [
      {
        description = "Bypass cache when session cookie is present"
        priority    = 100
        actions     = [{ type = "OverrideCacheTime", parameter1 = "0" }]
        triggers = [{
          type       = "RequestHeader"
          patterns   = ["*session=*"]
          parameter1 = "Cookie"
        }]
      },
      {
        description = "Cache anonymous GET requests at the edge"
        priority    = 900
        actions     = [{ type = "OverrideCacheTime", parameter1 = "300" }]
        triggers    = [{ type = "RequestMethod", patterns = ["GET"] }]
      },
    ]
  }
}
```

Bunny ignores query strings in the cache key unless `"querystring"` is in `cache_vary`.

### Middleware and Origin Shield

```hcl
pullzone_records = {
  "example-cdn" = {
    hostnames            = ["cdn", "*.cdn"]
    origin_url           = "http://s3-website.example.net"
    origin_http          = true
    forward_host_header  = false
    middleware           = file("${path.module}/s3-host-rewrite.ts")
    originshield_enabled = true
    originshield_zone    = "FR"
  }
}
```

## Upgrading from v2.x

1. Move every `cdn = true` A/CNAME into `pullzone_records`. The map key is the pull-zone name (pick a stable name ≤ 40 characters). `hostnames` is the list of record names that used to be `name` on those records. Set `origin_url` explicitly (`https://` plus the old record value, or `http://` with `origin_http = true`).
2. Move `pull_zones` list entries into the same map, keyed by today's `name`. Rename `record_names` to `hostnames`.
3. Move `cdn_edge_rules` onto the pull-zone entry that owns those hostnames. Drop the module-level `shield` input; omit `shield` on an entry for Basic on, or set `shield = { enabled = false }`.
4. `tofu state mv` the existing pull zone, Shield, and hostname resources onto `bunnynet_pullzone.this["<key>"]`, `bunnynet_pullzone_shield.this["<key>"]`, and `bunnynet_pullzone_hostname.this["<fqdn>"]`. Apex CDN records change from Bunny `PullZone` DNS type to CNAME and will replace.

DNS CNAMEs are created and hostnames attached in the same apply. Bunny will refuse hostname attach until live DNS already points at the pull zone (nameservers on Bunny, or CNAMEs already published). Retry the apply if the first one fails on a brand-new zone.

## DNSSEC

When `dnssec_enabled = true`, the module exposes:

- `dnssec_enabled` — whether DNSSEC is on for the zone
- `ds_record` — DS object (`key_id`, `algorithm`, `digest`) with Scaleway-style enum strings, or `null` until DS values are published

Use those values when configuring DNSSEC at your registrar (console or API).

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_bunnynet"></a> [bunnynet](#requirement\_bunnynet) | 0.18.1 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_bunnynet"></a> [bunnynet](#provider\_bunnynet) | 0.18.1 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [bunnynet_compute_script.pull_zone](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.1/docs/resources/compute_script) | resource |
| [bunnynet_dns_record.a](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.1/docs/resources/dns_record) | resource |
| [bunnynet_dns_record.cname](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.1/docs/resources/dns_record) | resource |
| [bunnynet_dns_record.mx](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.1/docs/resources/dns_record) | resource |
| [bunnynet_dns_record.pull_zone_cname](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.1/docs/resources/dns_record) | resource |
| [bunnynet_dns_record.txt](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.1/docs/resources/dns_record) | resource |
| [bunnynet_dns_zone.this](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.1/docs/resources/dns_zone) | resource |
| [bunnynet_pullzone.this](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.1/docs/resources/pullzone) | resource |
| [bunnynet_pullzone_edgerule.this](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.1/docs/resources/pullzone_edgerule) | resource |
| [bunnynet_pullzone_hostname.this](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.1/docs/resources/pullzone_hostname) | resource |
| [bunnynet_pullzone_shield.this](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.1/docs/resources/pullzone_shield) | resource |
| [bunnynet_storage_zone.this](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.1/docs/resources/storage_zone) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_a_records"></a> [a\_records](#input\_a\_records) | A records to create. Use name = "" for the apex. Empty list creates none. | <pre>list(object({<br/>    name  = string<br/>    value = string<br/>    ttl   = optional(number)<br/>  }))</pre> | `[]` | no |
| <a name="input_cname_records"></a> [cname\_records](#input\_cname\_records) | CNAME records to create. Use name = "" for the apex. Empty list creates none. | <pre>list(object({<br/>    name  = string<br/>    value = string<br/>    ttl   = optional(number)<br/>  }))</pre> | `[]` | no |
| <a name="input_dnssec_enabled"></a> [dnssec\_enabled](#input\_dnssec\_enabled) | Whether DNSSEC is enabled for the zone | `bool` | `true` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | Domain name for the Bunny.net DNS zone (e.g. example.com) | `string` | n/a | yes |
| <a name="input_mx_records"></a> [mx\_records](#input\_mx\_records) | MX records to create. Use name = "" for the apex. Empty list creates none. | <pre>list(object({<br/>    name     = string<br/>    value    = string<br/>    priority = number<br/>    ttl      = optional(number)<br/>  }))</pre> | `[]` | no |
| <a name="input_pullzone_records"></a> [pullzone\_records](#input\_pullzone\_records) | Map of Bunny pull zones keyed by the desired pull-zone name. Each entry<br/>creates one pull zone shared by every hostname in hostnames.<br/>hostnames are relative to the zone: "" is the apex, "*" is a wildcard,<br/>"cdn" is cdn.<domain>, "*.cdn" is *.cdn.<domain>. For each hostname the<br/>module creates a CNAME to <name>.<cdn\_domain> and attaches it as a TLS<br/>hostname on the pull zone.<br/>Do not also list those names in a\_records or cname\_records.<br/>Set exactly one of origin\_url or storage\_zone. origin\_url must be https://<br/>unless origin\_http = true (then http://). storage\_zone is a key from<br/>storage\_zones. Bunny takes TLS SNI from the origin\_url hostname, not the<br/>public hostname.<br/>Omit shield for Basic Shield on; set shield = { enabled = false } to skip it. | <pre>map(object({<br/>    hostnames    = list(string)<br/>    origin_url   = optional(string)<br/>    storage_zone = optional(string)<br/>    origin_http  = optional(bool, false)<br/>    middleware   = optional(string)<br/>    tls          = optional(bool, true)<br/>    force_ssl    = optional(bool, true)<br/>    # Send the client's Host header to the origin instead of the origin hostname.<br/>    forward_host_header           = optional(bool, true)<br/>    verify_ssl                    = optional(bool, true)<br/>    originshield_enabled          = optional(bool, false)<br/>    originshield_zone             = optional(string)<br/>    cache_expiration_time         = optional(number, 31919000)<br/>    cache_expiration_time_browser = optional(number)<br/>    cache_vary                    = optional(list(string), [])<br/>    cache_errors                  = optional(bool, false)<br/>    strip_cookies                 = optional(bool, false)<br/>    block_no_referer              = optional(bool, false)<br/>    # Bunny Smart Cache: only cache known-static extensions and MIME types.<br/>    smart_cache   = optional(bool, true)<br/>    cache_stale   = optional(list(string), [])<br/>    cache_chunked = optional(bool, false)<br/>    # Omit unless enabling; Bunny requires true (or unset) when cache_stale includes updating.<br/>    use_background_update      = optional(bool)<br/>    request_coalescing_enabled = optional(bool, false)<br/>    request_coalescing_timeout = optional(number, 30)<br/>    ttl                        = optional(number, 86400)<br/>    # Omit for Basic Shield on. enabled defaults true when the object is set.<br/>    shield = optional(object({<br/>      enabled    = optional(bool, true)<br/>      tier       = optional(string, "Basic")<br/>      ddos_level = optional(string, "Medium")<br/>      waf        = optional(bool, true)<br/>      waf_mode   = optional(string, "Log")<br/>    }))<br/>    edge_rules = optional(list(object({<br/>      description = optional(string, "")<br/>      enabled     = optional(bool, true)<br/>      match_type  = optional(string, "MatchAny")<br/>      priority    = number<br/>      actions = list(object({<br/>        type       = string<br/>        parameter1 = optional(string)<br/>        parameter2 = optional(string)<br/>        parameter3 = optional(string)<br/>      }))<br/>      triggers = list(object({<br/>        type       = string<br/>        match_type = optional(string, "MatchAny")<br/>        patterns   = list(string)<br/>        parameter1 = optional(string)<br/>        parameter2 = optional(string)<br/>      }))<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_storage_zones"></a> [storage\_zones](#input\_storage\_zones) | Map of Bunny Storage zones keyed by the storage-zone name. Each entry<br/>creates a storage zone the pull zones can use as origin. Edge tier<br/>requires region = "DE". Replication regions cannot be removed later<br/>without recreating the zone. | <pre>map(object({<br/>    region               = string<br/>    zone_tier            = optional(string, "Standard")<br/>    replication_regions  = optional(set(string), [])<br/>    custom_404_file_path = optional(string)<br/>    rewrite_404_to_200   = optional(bool, false)<br/>  }))</pre> | `{}` | no |
| <a name="input_txt_records"></a> [txt\_records](#input\_txt\_records) | TXT records to create. Use name = "" for the apex. Empty list creates none. | <pre>list(object({<br/>    name  = string<br/>    value = string<br/>    ttl   = optional(number)<br/>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_a_record_ids"></a> [a\_record\_ids](#output\_a\_record\_ids) | Map of A record keys to Bunny.net record IDs |
| <a name="output_cname_record_ids"></a> [cname\_record\_ids](#output\_cname\_record\_ids) | Map of CNAME record keys to Bunny.net record IDs |
| <a name="output_dnssec_enabled"></a> [dnssec\_enabled](#output\_dnssec\_enabled) | Whether DNSSEC is enabled on the Bunny.net DNS zone |
| <a name="output_domain"></a> [domain](#output\_domain) | Domain name of the DNS zone |
| <a name="output_ds_record"></a> [ds\_record](#output\_ds\_record) | DS record when DNSSEC is ready (key\_id / algorithm / digest with Scaleway-style<br/>enum strings). Null when DNSSEC is disabled or DS values are not yet published. |
| <a name="output_mx_record_ids"></a> [mx\_record\_ids](#output\_mx\_record\_ids) | Map of MX record keys to Bunny.net record IDs |
| <a name="output_nameserver1"></a> [nameserver1](#output\_nameserver1) | Primary nameserver for the DNS zone |
| <a name="output_nameserver2"></a> [nameserver2](#output\_nameserver2) | Secondary nameserver for the DNS zone |
| <a name="output_pull_zone_cdn_domains"></a> [pull\_zone\_cdn\_domains](#output\_pull\_zone\_cdn\_domains) | Map of pull zone names to the hostname their records CNAME to |
| <a name="output_pull_zone_hostname_ids"></a> [pull\_zone\_hostname\_ids](#output\_pull\_zone\_hostname\_ids) | Map of attached FQDNs to pull zone hostname IDs |
| <a name="output_pull_zone_ids"></a> [pull\_zone\_ids](#output\_pull\_zone\_ids) | Map of pull zone names to Bunny pull zone IDs |
| <a name="output_pull_zone_shield_ids"></a> [pull\_zone\_shield\_ids](#output\_pull\_zone\_shield\_ids) | Map of pull zone names with Bunny Shield enabled to their Shield IDs |
| <a name="output_pullzone_hostnames"></a> [pullzone\_hostnames](#output\_pullzone\_hostnames) | Every hostname this module attaches to a pull zone, mapped to the pull zone serving it |
| <a name="output_storage_zone_hostnames"></a> [storage\_zone\_hostnames](#output\_storage\_zone\_hostnames) | Map of storage zone names to their storage hostnames |
| <a name="output_storage_zone_ids"></a> [storage\_zone\_ids](#output\_storage\_zone\_ids) | Map of storage zone names to Bunny storage zone IDs |
| <a name="output_storage_zone_passwords"></a> [storage\_zone\_passwords](#output\_storage\_zone\_passwords) | Map of storage zone names to write passwords for the Storage HTTP API |
| <a name="output_storage_zone_passwords_readonly"></a> [storage\_zone\_passwords\_readonly](#output\_storage\_zone\_passwords\_readonly) | Map of storage zone names to read-only Storage HTTP API passwords |
| <a name="output_txt_record_ids"></a> [txt\_record\_ids](#output\_txt\_record\_ids) | Map of TXT record keys to Bunny.net record IDs |
| <a name="output_zone_id"></a> [zone\_id](#output\_zone\_id) | Bunny.net DNS zone ID |
<!-- END_TF_DOCS -->
