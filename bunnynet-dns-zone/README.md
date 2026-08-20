# bunnynet-dns-zone

OpenTofu module to manage a [Bunny.net DNS zone](https://registry.terraform.io/providers/BunnyWay/bunnynet/latest/docs/resources/dns_zone) and lists of A, CNAME, TXT, and MX records.

Use `name = ""` for apex records. Record list variables default to `[]` (none).

## Examples

### CNAME without CDN

A plain DNS CNAME — no pull zone, certificate, or Shield:

```hcl
module "dns" {
  source = "github.com/grrywlsn/tofu-modules.git//bunnynet-dns-zone?ref=bunnynet-dns-zone-v2.3.0"

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

### CNAME with a CDN pull zone and Shield

Set `cdn = true` to create a Terraform-managed [`bunnynet_pullzone`](https://registry.terraform.io/providers/BunnyWay/bunnynet/latest/docs/resources/pullzone) whose origin URL is `https://` plus the record value, and a Bunny `PullZone` DNS record that links the hostname to it. [Bunny Shield](https://bunny.net/docs/shield/) is on by default when `cdn = true` (set `shield = false` to skip it). SSL only validates once the domain's nameservers point at Bunny DNS. No edge rules are created unless you pass `cdn_edge_rules`.

The origin TLS certificate is verified by default (`verify_ssl = true`). Set `origin_http = true` for HTTP-only origins (for example an S3 website endpoint). Bunny takes TLS SNI from the origin hostname, not the public hostname: if the origin selects certificates by SNI, it must present a cert for the record value (or use a hostname-less origin listener). CDN pull zones cache at the edge for 31919000 seconds by default (`cache_expiration_time`); Bunny's `block_no_referer` default is overridden to false so direct visits are not blocked.

```hcl
module "dns" {
  source = "github.com/grrywlsn/tofu-modules.git//bunnynet-dns-zone?ref=bunnynet-dns-zone-v2.4.0"

  domain = "example.com"

  cname_records = [
    {
      name       = ""
      value      = "origin.example.net"
      ttl        = 86400
      cdn        = true
      shield     = true
      cache_vary = ["querystring"]
    },
  ]
}
```

Tune Shield via the module-level `shield` input (defaults: Basic tier, Medium DDoS, WAF on/Block).

### CNAME with CDN, Shield, and edge-cache rules

Pass `cdn_edge_rules` to attach Bunny edge rules to every `cdn = true` hostname. Per-record `edge_rules` overrides the module list (`[]` disables rules for that hostname only).

Lower priority numbers run first. [`OverrideCacheTime` short-circuits](https://bunny.net/docs/cdn/edge-rules/ordering) on the first match, so put bypasses ahead of caching rules. Bunny caps a trigger at 5 patterns; a single-trigger rule with more than 5 is split across consecutive priorities automatically.

Bunny ignores query strings in the cache key unless `"querystring"` is in `cache_vary`. Dynamic JSON endpoints such as `/api/route?path=` need that vary (or a bypass rule) or every path shares one cached body.

```hcl
module "dns" {
  source = "github.com/grrywlsn/tofu-modules.git//bunnynet-dns-zone?ref=bunnynet-dns-zone-v2.4.0"

  domain = "example.com"

  # Bypass session cookies / Authorization / auth paths, then cache anonymous
  # GETs for 5 minutes with no browser HTML cache.
  cdn_edge_rules = [
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
      description = "Bypass cache when Authorization header is present"
      priority    = 200
      actions     = [{ type = "OverrideCacheTime", parameter1 = "0" }]
      triggers = [{
        type       = "RequestHeader"
        patterns   = ["*"]
        parameter1 = "Authorization"
      }]
    },
    {
      description = "Bypass cache for auth, account, and inbox paths"
      priority    = 300
      actions     = [{ type = "OverrideCacheTime", parameter1 = "0" }]
      triggers = [{
        type = "Url"
        patterns = [
          "*/oauth/*",
          "*/login*",
          "*/account*",
          "*/admin*",
          "*/inbox*",
        ]
      }]
    },
    {
      description = "Cache anonymous GET requests at the edge"
      priority    = 900
      actions     = [{ type = "OverrideCacheTime", parameter1 = "300" }]
      triggers    = [{ type = "RequestMethod", patterns = ["GET"] }]
    },
    {
      description = "Override browser cache for GET responses"
      priority    = 910
      actions     = [{ type = "OverrideBrowserCacheTime", parameter1 = "0" }]
      triggers    = [{ type = "RequestMethod", patterns = ["GET"] }]
    },
  ]

  cname_records = [
    {
      name   = ""
      value  = "origin.example.net"
      ttl    = 86400
      cdn    = true
      shield = true
      cache_vary = ["querystring"]
    },
    {
      name   = "*"
      value  = "origin.example.net"
      ttl    = 86400
      cdn    = true
      shield = true
      cache_vary = ["querystring"]
    },
  ]
}
```

## Pull zones

For a multi-tenant or rewritten origin, or when several hostnames should share one pull zone, use `pull_zones` instead of `cdn = true`. That creates an explicit pull zone with optional middleware, plus a CNAME and a TLS hostname for every entry in `record_names`. Names are relative to the zone, so use `""` for the apex and a leading `*.` for a wildcard. Do not also list those names in `a_records` or `cname_records`. Wildcard Let's Encrypt certificates require the zone's nameservers to point at Bunny DNS.

```hcl
  pull_zones = [
    {
      name                          = "example-assets"
      record_names                  = ["assets", "*.assets"]
      origin_url                    = "https://origin.example.net"
      middleware                    = file("${path.module}/middleware.ts")
      originshield_enabled          = true
      originshield_zone             = "FR"
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

`origin_url` must be `https://`. Set `origin_http = true` and use `http://` only if the origin cannot speak TLS.

Bunny refuses to attach a hostname until live DNS already resolves to the pull zone, so a brand new zone needs two applies: set `create_hostnames = false` first to publish the CNAMEs, then flip it to `true` once they have propagated.

### Vary by query string

Bunny ignores the query string when building the cache key, so `?page=1` and `?page=2` share one cached object. Add `"querystring"` to `cache_vary` for any origin that returns different content per query parameter.

### Host-routed origins, Shield, and edge rules

A pull zone serving several hostnames still sends one fixed `origin_url`. Set `forward_host_header = true` so the origin sees the client's `Host` and can route by it, and add `"hostname"` to `cache_vary` so those hostnames do not share cache entries.

TLS is the catch: Bunny takes SNI from the `origin_url` hostname, not from the forwarded `Host`. An origin that selects its certificate by SNI — an Envoy Gateway or nginx with per-hostname listeners, for example — must present a certificate for the `origin_url` hostname and route requests arriving on it by `Host`. A listener with no hostname filter is the usual way to do that. Without it the handshake fails before any request is made. Origin TLS is verified by default (`verify_ssl = true`); set it to `false` only if the origin cannot present a valid certificate.

`shield = true` applies the module-level `shield` defaults to the pull zone. Explicit pull zones do not inherit `cdn_edge_rules`; give each one its own `edge_rules`, which take the same shape and the same 5-patterns-per-trigger chunking.

```hcl
  pull_zones = [
    {
      name                = "example-app"
      record_names        = ["", "*"]
      origin_url          = "https://origin.example.net"
      forward_host_header = true
      shield              = true
      cache_vary          = ["querystring", "hostname"]

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
    },
  ]
```

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
| [bunnynet_pullzone.cdn](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.0/docs/resources/pullzone) | resource |
| [bunnynet_pullzone.this](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.0/docs/resources/pullzone) | resource |
| [bunnynet_pullzone_edgerule.cdn](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.0/docs/resources/pullzone_edgerule) | resource |
| [bunnynet_pullzone_edgerule.pull_zone](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.0/docs/resources/pullzone_edgerule) | resource |
| [bunnynet_pullzone_hostname.this](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.0/docs/resources/pullzone_hostname) | resource |
| [bunnynet_pullzone_shield.cdn](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.0/docs/resources/pullzone_shield) | resource |
| [bunnynet_pullzone_shield.pull_zone](https://registry.terraform.io/providers/BunnyWay/bunnynet/0.18.0/docs/resources/pullzone_shield) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_a_records"></a> [a\_records](#input\_a\_records) | A records to create. Use name = "" for the apex. Empty list creates none.<br/>Set cdn = true to create a Terraform-managed Bunny pull zone for the<br/>hostname (origin URL derived from the record value) and a PullZone DNS<br/>record that links them. Bunny Shield is enabled by default when cdn = true;<br/>set shield = false to disable it. CDN records inherit module cdn\_edge\_rules<br/>unless edge\_rules is set on the record (including [] to attach none).<br/>Origin TLS is verified by default (verify\_ssl = true). | <pre>list(object({<br/>    name                       = string<br/>    value                      = string<br/>    ttl                        = optional(number)<br/>    cdn                        = optional(bool, false)<br/>    shield                     = optional(bool)<br/>    origin_http                = optional(bool, false)<br/>    forward_host_header        = optional(bool, true)<br/>    verify_ssl                 = optional(bool, true)<br/>    strip_cookies              = optional(bool, false)<br/>    cache_expiration_time      = optional(number, 31919000)<br/>    block_no_referer           = optional(bool, false)<br/>    cache_vary                 = optional(list(string), [])<br/>    cache_stale                = optional(list(string), [])<br/>    cache_chunked              = optional(bool, false)<br/>    use_background_update      = optional(bool, false)<br/>    request_coalescing_enabled = optional(bool, false)<br/>    request_coalescing_timeout = optional(number, 30)<br/>    edge_rules = optional(list(object({<br/>      description = optional(string, "")<br/>      enabled     = optional(bool, true)<br/>      match_type  = optional(string, "MatchAny")<br/>      priority    = number<br/>      actions = list(object({<br/>        type       = string<br/>        parameter1 = optional(string)<br/>        parameter2 = optional(string)<br/>        parameter3 = optional(string)<br/>      }))<br/>      triggers = list(object({<br/>        type       = string<br/>        match_type = optional(string, "MatchAny")<br/>        patterns   = list(string)<br/>        parameter1 = optional(string)<br/>        parameter2 = optional(string)<br/>      }))<br/>    })))<br/>  }))</pre> | `[]` | no |
| <a name="input_cdn_edge_rules"></a> [cdn\_edge\_rules](#input\_cdn\_edge\_rules) | Edge rules applied to every CDN (cdn = true) A/CNAME record that does not<br/>set its own edge\_rules. Default is [] (no rules). Pass an explicit list from<br/>the caller to configure cache/bypass (or any other) Bunny edge rules. Lower<br/>priority numbers run first; OverrideCacheTime short-circuits on the first<br/>match, so put bypasses at lower priorities than cache rules.<br/>Bunny allows at most 5 patterns per trigger: a single-trigger rule with more<br/>than 5 patterns is split across consecutive priorities automatically. | <pre>list(object({<br/>    description = optional(string, "")<br/>    enabled     = optional(bool, true)<br/>    match_type  = optional(string, "MatchAny")<br/>    priority    = number<br/>    actions = list(object({<br/>      type       = string<br/>      parameter1 = optional(string)<br/>      parameter2 = optional(string)<br/>      parameter3 = optional(string)<br/>    }))<br/>    triggers = list(object({<br/>      type       = string<br/>      match_type = optional(string, "MatchAny")<br/>      patterns   = list(string)<br/>      parameter1 = optional(string)<br/>      parameter2 = optional(string)<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_cname_records"></a> [cname\_records](#input\_cname\_records) | CNAME records to create. Use name = "" for the apex. Empty list creates none.<br/>Set cdn = true to create a Terraform-managed Bunny pull zone for the<br/>hostname (origin URL derived from the record value) and a PullZone DNS<br/>record that links them. Bunny Shield is enabled by default when cdn = true;<br/>set shield = false to disable it. CDN records inherit module cdn\_edge\_rules<br/>unless edge\_rules is set on the record (including [] to attach none).<br/>Origin TLS is verified by default (verify\_ssl = true). | <pre>list(object({<br/>    name                       = string<br/>    value                      = string<br/>    ttl                        = optional(number)<br/>    cdn                        = optional(bool, false)<br/>    shield                     = optional(bool)<br/>    origin_http                = optional(bool, false)<br/>    forward_host_header        = optional(bool, true)<br/>    verify_ssl                 = optional(bool, true)<br/>    strip_cookies              = optional(bool, false)<br/>    cache_expiration_time      = optional(number, 31919000)<br/>    block_no_referer           = optional(bool, false)<br/>    cache_vary                 = optional(list(string), [])<br/>    cache_stale                = optional(list(string), [])<br/>    cache_chunked              = optional(bool, false)<br/>    use_background_update      = optional(bool, false)<br/>    request_coalescing_enabled = optional(bool, false)<br/>    request_coalescing_timeout = optional(number, 30)<br/>    edge_rules = optional(list(object({<br/>      description = optional(string, "")<br/>      enabled     = optional(bool, true)<br/>      match_type  = optional(string, "MatchAny")<br/>      priority    = number<br/>      actions = list(object({<br/>        type       = string<br/>        parameter1 = optional(string)<br/>        parameter2 = optional(string)<br/>        parameter3 = optional(string)<br/>      }))<br/>      triggers = list(object({<br/>        type       = string<br/>        match_type = optional(string, "MatchAny")<br/>        patterns   = list(string)<br/>        parameter1 = optional(string)<br/>        parameter2 = optional(string)<br/>      }))<br/>    })))<br/>  }))</pre> | `[]` | no |
| <a name="input_dnssec_enabled"></a> [dnssec\_enabled](#input\_dnssec\_enabled) | Whether DNSSEC is enabled for the zone | `bool` | `true` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | Domain name for the Bunny.net DNS zone (e.g. example.com) | `string` | n/a | yes |
| <a name="input_mx_records"></a> [mx\_records](#input\_mx\_records) | MX records to create. Use name = "" for the apex. Empty list creates none. | <pre>list(object({<br/>    name     = string<br/>    value    = string<br/>    priority = number<br/>    ttl      = optional(number)<br/>  }))</pre> | `[]` | no |
| <a name="input_pull_zones"></a> [pull\_zones](#input\_pull\_zones) | Explicit Bunny pull zones attached to this DNS zone. Distinct from record-level<br/>cdn = true. Each entry creates a pull zone and, for every record\_names entry, a<br/>CNAME pointing at the pull zone plus a matching pull zone hostname. Record<br/>names are relative to the zone: use "" for the apex and a leading "*." for<br/>wildcards (e.g. ["assets", "*.assets"]). Do not also list those names in<br/>a\_records or cname\_records.<br/>Set middleware to a Bunny compute script (type middleware) that rewrites origin<br/>requests. origin\_url must be https:// unless origin\_http = true.<br/>Set forward\_host\_header = true when the origin routes by hostname; note that<br/>Bunny still uses the origin\_url hostname for TLS SNI, so the origin needs a<br/>certificate and route for that name. Origin TLS is verified by default<br/>(verify\_ssl = true). Set shield = true to apply the module-level shield<br/>defaults. These pull zones do not inherit cdn\_edge\_rules: pass edge\_rules<br/>per pull zone. | <pre>list(object({<br/>    name         = string<br/>    origin_url   = string<br/>    record_names = list(string)<br/>    origin_http  = optional(bool, false)<br/>    # Bunny validates that live DNS already resolves to the pull zone before it will<br/>    # attach a hostname or issue a certificate. Set false for the first apply so the<br/>    # CNAMEs are created, then true once they have propagated.<br/>    create_hostnames = optional(bool, true)<br/>    middleware       = optional(string)<br/>    tls              = optional(bool, true)<br/>    force_ssl        = optional(bool, true)<br/>    # Send the client's Host header to the origin instead of the origin hostname.<br/>    forward_host_header = optional(bool, false)<br/>    # Verify the origin TLS certificate. Defaults to true.<br/>    verify_ssl = optional(bool, true)<br/>    # Bunny Shield, configured from the module-level shield input.<br/>    shield                        = optional(bool, false)<br/>    originshield_enabled          = optional(bool, false)<br/>    originshield_zone             = optional(string)<br/>    cache_expiration_time         = optional(number)<br/>    cache_expiration_time_browser = optional(number)<br/>    cache_vary                    = optional(list(string), [])<br/>    cache_errors                  = optional(bool, false)<br/>    # Bunny strips Set-Cookie from origin responses by default, which breaks any<br/>    # origin that logs users in. Set false for application origins.<br/>    strip_cookies = optional(bool, true)<br/>    # Bunny blocks requests with no Referer by default; that breaks direct<br/>    # visits. Default off.<br/>    block_no_referer = optional(bool, false)<br/>    # Serve stale content while the origin is unreachable and/or while Bunny is<br/>    # refreshing the object. Empty disables stale serving.<br/>    cache_stale = optional(list(string), [])<br/>    # Optimize for large object delivery (cache slicing).<br/>    cache_chunked = optional(bool, false)<br/>    # Refresh expired objects in the background while continuing to serve the<br/>    # cached response.<br/>    use_background_update = optional(bool, false)<br/>    # Collapse concurrent cache-MISS requests for the same URL into a single<br/>    # origin fetch.<br/>    request_coalescing_enabled = optional(bool, false)<br/>    # Seconds to wait for a coalesced origin response before falling through.<br/>    request_coalescing_timeout = optional(number, 30)<br/>    # TTL in seconds for the CNAME records that point at this pull zone.<br/>    ttl = optional(number, 86400)<br/>    # Bunny edge rules for this pull zone. Same shape and chunking rules as<br/>    # cdn_edge_rules, which explicit pull zones do not inherit.<br/>    edge_rules = optional(list(object({<br/>      description = optional(string, "")<br/>      enabled     = optional(bool, true)<br/>      match_type  = optional(string, "MatchAny")<br/>      priority    = number<br/>      actions = list(object({<br/>        type       = string<br/>        parameter1 = optional(string)<br/>        parameter2 = optional(string)<br/>        parameter3 = optional(string)<br/>      }))<br/>      triggers = list(object({<br/>        type       = string<br/>        match_type = optional(string, "MatchAny")<br/>        patterns   = list(string)<br/>        parameter1 = optional(string)<br/>        parameter2 = optional(string)<br/>      }))<br/>    })), [])<br/>  }))</pre> | `[]` | no |
| <a name="input_shield"></a> [shield](#input\_shield) | Defaults applied to Bunny Shield when a pull zone is created for a cdn = true<br/>record or a pull\_zones entry with shield = true (unless that record sets<br/>shield = false).<br/>See https://bunny.net/docs/shield/ for plan tiers and options. | <pre>object({<br/>    tier       = optional(string, "Basic")<br/>    ddos_level = optional(string, "Medium")<br/>    waf        = optional(bool, true)<br/>    waf_mode   = optional(string, "Block")<br/>  })</pre> | `{}` | no |
| <a name="input_txt_records"></a> [txt\_records](#input\_txt\_records) | TXT records to create. Use name = "" for the apex. Empty list creates none. | <pre>list(object({<br/>    name  = string<br/>    value = string<br/>    ttl   = optional(number)<br/>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_a_cdn_pullzone_ids"></a> [a\_cdn\_pullzone\_ids](#output\_a\_cdn\_pullzone\_ids) | Map of A record keys with cdn = true to their Terraform-managed pull zone IDs |
| <a name="output_a_record_ids"></a> [a\_record\_ids](#output\_a\_record\_ids) | Map of A record keys to Bunny.net record IDs |
| <a name="output_a_shield_ids"></a> [a\_shield\_ids](#output\_a\_shield\_ids) | Map of CDN A-record pull zones with Bunny Shield enabled to their Shield IDs |
| <a name="output_cdn_pullzone_ids"></a> [cdn\_pullzone\_ids](#output\_cdn\_pullzone\_ids) | Map of cdn = true record keys (a/… or cname/…) to Terraform-managed pull zone IDs |
| <a name="output_cname_cdn_pullzone_ids"></a> [cname\_cdn\_pullzone\_ids](#output\_cname\_cdn\_pullzone\_ids) | Map of CNAME record keys with cdn = true to their Terraform-managed pull zone IDs |
| <a name="output_cname_record_ids"></a> [cname\_record\_ids](#output\_cname\_record\_ids) | Map of CNAME record keys to Bunny.net record IDs |
| <a name="output_cname_shield_ids"></a> [cname\_shield\_ids](#output\_cname\_shield\_ids) | Map of CDN CNAME-record pull zones with Bunny Shield enabled to their Shield IDs |
| <a name="output_dnssec_enabled"></a> [dnssec\_enabled](#output\_dnssec\_enabled) | Whether DNSSEC is enabled on the Bunny.net DNS zone |
| <a name="output_domain"></a> [domain](#output\_domain) | Domain name of the DNS zone |
| <a name="output_ds_record"></a> [ds\_record](#output\_ds\_record) | DS record when DNSSEC is ready (key\_id / algorithm / digest with Scaleway-style<br/>enum strings). Null when DNSSEC is disabled or DS values are not yet published. |
| <a name="output_mx_record_ids"></a> [mx\_record\_ids](#output\_mx\_record\_ids) | Map of MX record keys to Bunny.net record IDs |
| <a name="output_nameserver1"></a> [nameserver1](#output\_nameserver1) | Primary nameserver for the DNS zone |
| <a name="output_nameserver2"></a> [nameserver2](#output\_nameserver2) | Secondary nameserver for the DNS zone |
| <a name="output_pull_zone_cdn_domains"></a> [pull\_zone\_cdn\_domains](#output\_pull\_zone\_cdn\_domains) | Map of pull zone names to the hostname their records CNAME to |
| <a name="output_pull_zone_ids"></a> [pull\_zone\_ids](#output\_pull\_zone\_ids) | Map of pull zone names to Bunny pull zone IDs |
| <a name="output_pull_zone_shield_ids"></a> [pull\_zone\_shield\_ids](#output\_pull\_zone\_shield\_ids) | Map of pull zone names with Bunny Shield enabled to their Shield IDs |
| <a name="output_txt_record_ids"></a> [txt\_record\_ids](#output\_txt\_record\_ids) | Map of TXT record keys to Bunny.net record IDs |
| <a name="output_zone_id"></a> [zone\_id](#output\_zone\_id) | Bunny.net DNS zone ID |
<!-- END_TF_DOCS -->
