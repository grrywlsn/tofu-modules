locals {
  pull_zones = {
    for zone in var.pull_zones : zone.name => zone
  }

  pull_zone_middleware = {
    for k, zone in local.pull_zones : k => zone
    if zone.middleware != null && trimspace(coalesce(zone.middleware, "")) != ""
  }

  # Keyed by hostname; record_names are validated unique across all pull zones.
  pull_zone_records = {
    for rec in flatten([
      for k, zone in local.pull_zones : [
        for record_name in zone.record_names : {
          zone_key    = k
          record_name = record_name
          hostname    = record_name != "" ? "${record_name}.${var.domain}" : var.domain
        }
      ]
    ]) : rec.hostname => rec
  }

  pull_zone_hostnames = {
    for k, rec in local.pull_zone_records : k => rec
    if local.pull_zones[rec.zone_key].create_hostnames
  }
}

resource "bunnynet_compute_script" "pull_zone" {
  for_each = local.pull_zone_middleware

  type    = "middleware"
  name    = "${each.value.name}-middleware"
  content = each.value.middleware
}

resource "bunnynet_pullzone" "this" {
  for_each = local.pull_zones

  name = each.value.name

  origin {
    type                = "OriginUrl"
    url                 = each.value.origin_url
    forward_host_header = false
    follow_redirects    = true
    middleware_script   = try(bunnynet_compute_script.pull_zone[each.key].id, null)
  }

  originshield_enabled = each.value.originshield_enabled
  originshield_zone    = each.value.originshield_enabled ? each.value.originshield_zone : null

  cache_errors                  = each.value.cache_errors
  cache_expiration_time         = each.value.cache_expiration_time
  cache_expiration_time_browser = each.value.cache_expiration_time_browser
  cache_vary                    = toset(each.value.cache_vary)
  cache_stale                   = toset(each.value.cache_stale)
  cache_chunked                 = each.value.cache_chunked
  use_background_update         = each.value.use_background_update
  request_coalescing_enabled    = each.value.request_coalescing_enabled
  request_coalescing_timeout    = each.value.request_coalescing_timeout

  routing {
    tier = "Standard"
    # Bunny requires "scripting" when middleware_script is set. Do not also send
    # "all": the API drops it and the provider treats that as an inconsistent result.
    filters = contains(keys(local.pull_zone_middleware), each.key) ? toset(["scripting"]) : null
  }
}

resource "bunnynet_dns_record" "pull_zone_cname" {
  for_each = local.pull_zone_records

  zone = bunnynet_dns_zone.this.id
  name = each.value.record_name
  type = "CNAME"
  # cdn_domain is the shared parent (e.g. b-cdn.net); records must point at the
  # pull zone's own hostname below it.
  value       = "${bunnynet_pullzone.this[each.value.zone_key].name}.${bunnynet_pullzone.this[each.value.zone_key].cdn_domain}"
  ttl         = local.pull_zones[each.value.zone_key].ttl
  accelerated = false
}

resource "bunnynet_pullzone_hostname" "this" {
  for_each = local.pull_zone_hostnames

  pullzone    = bunnynet_pullzone.this[each.value.zone_key].id
  name        = each.value.hostname
  tls_enabled = local.pull_zones[each.value.zone_key].tls
  force_ssl   = local.pull_zones[each.value.zone_key].force_ssl

  # Bunny validates that live DNS already points at the pull zone.
  depends_on = [bunnynet_dns_record.pull_zone_cname]
}
