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

CDN-accelerated hostnames get a **secure-by-default** edge-cache policy (`cdn_cache`):

- Bypass cache when the `Cookie` header matches `*session=*` (or your patterns)
- Bypass cache when an `Authorization` header is present
- Bypass cache on common auth/admin/inbox URL patterns
- Cache anonymous `GET` responses at the edge for 300s
- Override browser cache for `GET` to 0s (no HTML caching in the browser)

Defaults apply with no extra config—just `cdn = true`. Override at module level or per record:

```hcl
  # Module-wide defaults (optional — these are already the defaults)
  # cdn_cache = {
  #   cache_expiration_time         = 300
  #   override_browser_cache        = true
  #   browser_cache_expiration_time = 0
  #   bypass_authorization          = true
  #   bypass_cookie_patterns        = ["*session=*"]
  #   bypass_url_patterns = [
  #     "*/oauth/*", "*/login*", "*/account*", "*/admin*", "*/inbox*",
  #   ]
  # }

  cname_records = [
    {
      name  = ""
      value = "origin.example.net"
      cdn   = true
      # Optional per-record overrides (partial — unset fields inherit module defaults)
      # cdn_cache = {
      #   cache_expiration_time  = 600
      #   bypass_cookie_patterns = ["*session=*", "*auth=*"]
      # }
    },
  ]
```

Set `bypass_*` lists to `[]` to disable that bypass. Set module `cache_expiration_time = null` (or per-record `0`) to turn off anonymous GET caching.

Bunny caps an edge rule at 5 patterns per condition, so longer `bypass_*` lists are split across consecutive rules automatically. Bypass rules always take lower priority numbers than the caching rules: Bunny runs rules from the lowest number up and [`OverrideCacheTime` short-circuits](https://bunny.net/docs/cdn/edge-rules/ordering) on the first match, so an authenticated request can never fall through to the caching rule.

For a multi-tenant or rewritten origin, use `pull_zones` instead of `cdn = true`. That creates an explicit pull zone with optional middleware, plus a CNAME and a TLS hostname for every entry in `record_names`. Names are relative to the zone, so use `""` for the apex and a leading `*.` for a wildcard. Do not also list those names in `a_records` or `cname_records`. Wildcard Let's Encrypt certificates require the zone's nameservers to point at Bunny DNS.

```hcl
  pull_zones = [
    {
      name                  = "example-assets"
      record_names          = ["assets", "*.assets"]
      origin_url            = "http://origin.example.net"
      middleware            = file("${path.module}/middleware.ts")
      originshield_enabled  = true
      originshield_zone     = "FR"
      cache_expiration_time         = 31536000
      cache_expiration_time_browser = 31536000
      cache_vary                    = ["hostname"]
      cache_stale                   = ["offline", "updating"]
      cache_chunked                 = true
      use_background_update         = true
      request_coalescing_enabled    = true
      ttl                           = 86400
    },
  ]
```

Bunny refuses to attach a hostname until live DNS already resolves to the pull zone, so a brand new zone needs two applies: set `create_hostnames = false` first to publish the CNAMEs, then flip it to `true` once they have propagated.

### Upgrading from v1.6.x

`pull_zones` no longer takes `record_name` / `wildcard` / `hostnames`. Replace them with `record_names` (list) and `create_hostnames`:

```hcl
# before
record_name = "cdn"
wildcard    = true
hostnames   = true

# after
record_names     = ["cdn", "*.cdn"]
create_hostnames = true
```

Pull zone resources are also re-keyed by pull zone name and hostname, so existing callers should `tofu state mv` before applying or the pull zone will be recreated.

[Bunny Shield](https://bunny.net/docs/shield/) is enabled by default whenever `cdn = true`. Set `shield = false` on a record to skip it. Tune tier / DDoS / WAF via the module-level `shield` input (defaults: Basic, Medium, WAF on/Block).

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
| [bunnynet_compute_script.pull_zone](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.0/docs/resources/compute_script) | resource |
| [bunnynet_dns_record.a](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.0/docs/resources/dns_record) | resource |
| [bunnynet_dns_record.cname](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.0/docs/resources/dns_record) | resource |
| [bunnynet_dns_record.mx](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.0/docs/resources/dns_record) | resource |
| [bunnynet_dns_record.pull_zone_cname](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.0/docs/resources/dns_record) | resource |
| [bunnynet_dns_record.txt](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.0/docs/resources/dns_record) | resource |
| [bunnynet_dns_zone.this](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.0/docs/resources/dns_zone) | resource |
| [bunnynet_pullzone.this](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.0/docs/resources/pullzone) | resource |
| [bunnynet_pullzone_edgerule.a_browser_cache_get](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.0/docs/resources/pullzone_edgerule) | resource |
| [bunnynet_pullzone_edgerule.a_bypass_authorization](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.0/docs/resources/pullzone_edgerule) | resource |
| [bunnynet_pullzone_edgerule.a_bypass_cookie](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.0/docs/resources/pullzone_edgerule) | resource |
| [bunnynet_pullzone_edgerule.a_bypass_url](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.0/docs/resources/pullzone_edgerule) | resource |
| [bunnynet_pullzone_edgerule.a_cache_get](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.0/docs/resources/pullzone_edgerule) | resource |
| [bunnynet_pullzone_edgerule.cname_browser_cache_get](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.0/docs/resources/pullzone_edgerule) | resource |
| [bunnynet_pullzone_edgerule.cname_bypass_authorization](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.0/docs/resources/pullzone_edgerule) | resource |
| [bunnynet_pullzone_edgerule.cname_bypass_cookie](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.0/docs/resources/pullzone_edgerule) | resource |
| [bunnynet_pullzone_edgerule.cname_bypass_url](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.0/docs/resources/pullzone_edgerule) | resource |
| [bunnynet_pullzone_edgerule.cname_cache_get](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.0/docs/resources/pullzone_edgerule) | resource |
| [bunnynet_pullzone_hostname.this](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.0/docs/resources/pullzone_hostname) | resource |
| [bunnynet_pullzone_shield.a](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.0/docs/resources/pullzone_shield) | resource |
| [bunnynet_pullzone_shield.cname](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.0/docs/resources/pullzone_shield) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_a_records"></a> [a\_records](#input\_a\_records) | A records to create. Use name = "" for the apex. Empty list creates none.<br/>Set cdn = true to enable Bunny CDN Acceleration for the hostname (creates a<br/>pull zone and issues a Let's Encrypt certificate for it). Bunny Shield is<br/>enabled by default when cdn = true; set shield = false to disable it.<br/>CDN-accelerated records get the module cdn\_cache edge-rule policy by default;<br/>set cdn\_cache on a record to override those defaults. | <pre>list(object({<br/>    name   = string<br/>    value  = string<br/>    ttl    = optional(number)<br/>    cdn    = optional(bool, false)<br/>    shield = optional(bool)<br/>    cdn_cache = optional(object({<br/>      cache_expiration_time         = optional(number)<br/>      browser_cache_expiration_time = optional(number)<br/>      override_browser_cache        = optional(bool)<br/>      bypass_authorization          = optional(bool)<br/>      bypass_cookie_patterns        = optional(list(string))<br/>      bypass_url_patterns           = optional(list(string))<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_cdn_cache"></a> [cdn\_cache](#input\_cdn\_cache) | Default edge-cache policy for CDN-accelerated (cdn = true) A/CNAME records.<br/>Secure defaults: bypass when a session cookie or Authorization header is<br/>present, bypass common auth/admin/inbox paths, cache anonymous GETs for 5<br/>minutes at the edge, and prevent browsers from caching HTML (0s).<br/>Per-record cdn\_cache overrides these values (partial overrides inherit the<br/>rest). Set bypass\_* lists to [] to disable that bypass; set<br/>cache\_expiration\_time to null (module) or 0 (per-record) to disable<br/>anonymous GET caching. | <pre>object({<br/>    # Anonymous GET edge TTL in seconds. null disables the anonymous GET rule.<br/>    cache_expiration_time = optional(number, 300)<br/>    # When override_browser_cache is true, set browser Cache-Control max-age.<br/>    override_browser_cache        = optional(bool, true)<br/>    browser_cache_expiration_time = optional(number, 0)<br/>    # Bypass edge cache when Authorization is present (API / Bearer clients).<br/>    bypass_authorization = optional(bool, true)<br/>    # Bypass when Cookie matches any pattern (e.g. "*session=*").<br/>    bypass_cookie_patterns = optional(list(string), ["*session=*"])<br/>    # Bypass when request URL matches any pattern. Bunny allows 5 patterns per<br/>    # edge rule, so longer lists are split across consecutive rules.<br/>    bypass_url_patterns = optional(list(string), [<br/>      "*/oauth/*",<br/>      "*/login*",<br/>      "*/account*",<br/>      "*/admin*",<br/>      "*/inbox*",<br/>    ])<br/>  })</pre> | `{}` | no |
| <a name="input_cname_records"></a> [cname\_records](#input\_cname\_records) | CNAME records to create. Use name = "" for the apex. Empty list creates none.<br/>Set cdn = true to enable Bunny CDN Acceleration for the hostname (creates a<br/>pull zone and issues a Let's Encrypt certificate for it). Bunny Shield is<br/>enabled by default when cdn = true; set shield = false to disable it.<br/>CDN-accelerated records get the module cdn\_cache edge-rule policy by default;<br/>set cdn\_cache on a record to override those defaults. | <pre>list(object({<br/>    name   = string<br/>    value  = string<br/>    ttl    = optional(number)<br/>    cdn    = optional(bool, false)<br/>    shield = optional(bool)<br/>    cdn_cache = optional(object({<br/>      cache_expiration_time         = optional(number)<br/>      browser_cache_expiration_time = optional(number)<br/>      override_browser_cache        = optional(bool)<br/>      bypass_authorization          = optional(bool)<br/>      bypass_cookie_patterns        = optional(list(string))<br/>      bypass_url_patterns           = optional(list(string))<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_dnssec_enabled"></a> [dnssec\_enabled](#input\_dnssec\_enabled) | Whether DNSSEC is enabled for the zone | `bool` | `true` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | Domain name for the Bunny.net DNS zone (e.g. example.com) | `string` | n/a | yes |
| <a name="input_mx_records"></a> [mx\_records](#input\_mx\_records) | MX records to create. Use name = "" for the apex. Empty list creates none. | <pre>list(object({<br/>    name     = string<br/>    value    = string<br/>    priority = number<br/>    ttl      = optional(number)<br/>  }))</pre> | `[]` | no |
| <a name="input_pull_zones"></a> [pull\_zones](#input\_pull\_zones) | Explicit Bunny pull zones attached to this DNS zone. Distinct from record-level<br/>cdn = true (CDN Acceleration). Each entry creates a pull zone and, for every<br/>record\_names entry, a CNAME pointing at the pull zone plus a matching pull zone<br/>hostname. Record names are relative to the zone: use "" for the apex and a<br/>leading "*." for wildcards (e.g. ["assets", "*.assets"]). Do not also list those<br/>names in a\_records or cname\_records.<br/>Set middleware to a Bunny compute script (type middleware) that rewrites origin<br/>requests. Shield/WAF is not enabled for these pull zones. | <pre>list(object({<br/>    name         = string<br/>    origin_url   = string<br/>    record_names = list(string)<br/>    # Bunny validates that live DNS already resolves to the pull zone before it will<br/>    # attach a hostname or issue a certificate. Set false for the first apply so the<br/>    # CNAMEs are created, then true once they have propagated.<br/>    create_hostnames              = optional(bool, true)<br/>    middleware                    = optional(string)<br/>    tls                           = optional(bool, true)<br/>    force_ssl                     = optional(bool, true)<br/>    originshield_enabled          = optional(bool, false)<br/>    originshield_zone             = optional(string)<br/>    cache_expiration_time         = optional(number)<br/>    cache_expiration_time_browser = optional(number)<br/>    cache_vary                    = optional(list(string), [])<br/>    cache_errors                  = optional(bool, false)<br/>    # Serve stale content while the origin is unreachable and/or while Bunny is<br/>    # refreshing the object. Empty disables stale serving.<br/>    cache_stale = optional(list(string), [])<br/>    # Optimize for large object delivery (cache slicing).<br/>    cache_chunked = optional(bool, false)<br/>    # Refresh expired objects in the background while continuing to serve the<br/>    # cached response.<br/>    use_background_update = optional(bool, false)<br/>    # Collapse concurrent cache-MISS requests for the same URL into a single<br/>    # origin fetch.<br/>    request_coalescing_enabled = optional(bool, false)<br/>    # Seconds to wait for a coalesced origin response before falling through.<br/>    request_coalescing_timeout = optional(number, 30)<br/>    # TTL in seconds for the CNAME records that point at this pull zone.<br/>    ttl = optional(number, 86400)<br/>  }))</pre> | `[]` | no |
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
| <a name="output_ds_record"></a> [ds\_record](#output\_ds\_record) | DS record when DNSSEC is ready (key\_id / algorithm / digest with Scaleway-style<br/>enum strings). Null when DNSSEC is disabled or DS values are not yet published. |
| <a name="output_mx_record_ids"></a> [mx\_record\_ids](#output\_mx\_record\_ids) | Map of MX record keys to Bunny.net record IDs |
| <a name="output_nameserver1"></a> [nameserver1](#output\_nameserver1) | Primary nameserver for the DNS zone |
| <a name="output_nameserver2"></a> [nameserver2](#output\_nameserver2) | Secondary nameserver for the DNS zone |
| <a name="output_pull_zone_cdn_domains"></a> [pull\_zone\_cdn\_domains](#output\_pull\_zone\_cdn\_domains) | Map of pull zone names to the hostname their records CNAME to |
| <a name="output_pull_zone_ids"></a> [pull\_zone\_ids](#output\_pull\_zone\_ids) | Map of pull zone names to Bunny pull zone IDs |
| <a name="output_txt_record_ids"></a> [txt\_record\_ids](#output\_txt\_record\_ids) | Map of TXT record keys to Bunny.net record IDs |
| <a name="output_zone_id"></a> [zone\_id](#output\_zone\_id) | Bunny.net DNS zone ID |
<!-- END_TF_DOCS -->
