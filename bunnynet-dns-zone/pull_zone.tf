locals {
  pull_zone_middleware = {
    for k, zone in var.pullzone_records : k => zone
    if zone.middleware != null && trimspace(coalesce(zone.middleware, "")) != ""
  }

  # Keyed by FQDN; hostnames are validated unique across all pull zones.
  pull_zone_host_records = {
    for rec in flatten([
      for k, zone in var.pullzone_records : [
        for record_name in zone.hostnames : {
          zone_key    = k
          record_name = record_name
          hostname    = record_name != "" ? "${record_name}.${var.domain}" : var.domain
        }
      ]
    ]) : rec.hostname => rec
  }

  pull_zone_shields = {
    for k, zone in var.pullzone_records : k => coalesce(zone.shield, {
      enabled    = true
      tier       = "Basic"
      ddos_level = "Medium"
      waf        = true
      waf_mode   = "Log"
    })
    if zone.shield == null || zone.shield.enabled
  }
}

resource "bunnynet_compute_script" "pull_zone" {
  for_each = local.pull_zone_middleware

  type    = "middleware"
  name    = "${each.key}-middleware"
  content = each.value.middleware
}

resource "bunnynet_pullzone" "this" {
  for_each = var.pullzone_records

  name = each.key

  origin {
    type                = each.value.storage_zone != null ? "StorageZone" : "OriginUrl"
    url                 = each.value.storage_zone != null ? null : each.value.origin_url
    storagezone         = each.value.storage_zone != null ? bunnynet_storage_zone.this[each.value.storage_zone].id : null
    forward_host_header = each.value.storage_zone != null ? null : each.value.forward_host_header
    verify_ssl          = each.value.storage_zone != null ? null : each.value.verify_ssl
    follow_redirects    = each.value.storage_zone != null ? null : true
    middleware_script   = try(bunnynet_compute_script.pull_zone[each.key].id, null)
  }

  originshield_enabled = each.value.originshield_enabled
  originshield_zone    = each.value.originshield_enabled ? each.value.originshield_zone : null

  cache_errors                  = each.value.cache_errors
  cache_enabled                 = each.value.smart_cache
  strip_cookies                 = each.value.strip_cookies
  block_no_referer              = each.value.block_no_referer
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
  for_each = local.pull_zone_host_records

  zone = bunnynet_dns_zone.this.id
  name = each.value.record_name
  # Apex cannot be a CNAME next to TXT/MX; Bunny's PullZone record type can.
  type = each.value.record_name == "" ? "PullZone" : "CNAME"
  value = (
    each.value.record_name == ""
    ? bunnynet_pullzone.this[each.value.zone_key].name
    : "${bunnynet_pullzone.this[each.value.zone_key].name}.${bunnynet_pullzone.this[each.value.zone_key].cdn_domain}"
  )
  ttl         = var.pullzone_records[each.value.zone_key].ttl
  accelerated = false
  pullzone_id = each.value.record_name == "" ? bunnynet_pullzone.this[each.value.zone_key].id : null
}

resource "bunnynet_pullzone_hostname" "this" {
  for_each = local.pull_zone_host_records

  pullzone    = bunnynet_pullzone.this[each.value.zone_key].id
  name        = each.value.hostname
  tls_enabled = var.pullzone_records[each.value.zone_key].tls
  force_ssl   = var.pullzone_records[each.value.zone_key].force_ssl

  # Bunny validates that live DNS already points at the pull zone.
  depends_on = [bunnynet_dns_record.pull_zone_cname]
}

resource "bunnynet_pullzone_shield" "this" {
  for_each = local.pull_zone_shields

  pullzone = bunnynet_pullzone.this[each.key].id
  tier     = each.value.tier

  ddos {
    level = each.value.ddos_level
  }

  waf {
    enabled = each.value.waf
    mode    = each.value.waf_mode
  }
}
