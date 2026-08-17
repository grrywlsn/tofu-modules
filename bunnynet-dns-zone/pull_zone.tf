locals {
  pull_zones = {
    for idx, zone in var.pull_zones :
    "${zone.record_name}-${idx}" => zone
  }

  pull_zone_middleware = {
    for k, zone in local.pull_zones : k => zone
    if zone.middleware != null && trimspace(coalesce(zone.middleware, "")) != ""
  }

  pull_zone_cnames = {
    for rec in flatten([
      for k, zone in local.pull_zones : concat(
        [{ key = "${k}-apex", zone_key = k, name = zone.record_name }],
        zone.wildcard ? [{ key = "${k}-wildcard", zone_key = k, name = "*.${zone.record_name}" }] : []
      )
      ]) : rec.key => {
      zone_key = rec.zone_key
      name     = rec.name
    }
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

  cache_errors          = each.value.cache_errors
  cache_expiration_time = each.value.cache_expiration_time
  cache_vary            = toset(each.value.cache_vary)

  routing {
    tier    = "Standard"
    filters = contains(keys(local.pull_zone_middleware), each.key) ? toset(["all", "scripting"]) : toset(["all"])
  }
}

resource "bunnynet_pullzone_hostname" "record" {
  for_each = local.pull_zones

  pullzone    = bunnynet_pullzone.this[each.key].id
  name        = "${each.value.record_name}.${var.domain}"
  tls_enabled = each.value.tls
  force_ssl   = each.value.force_ssl
}

resource "bunnynet_pullzone_hostname" "wildcard" {
  for_each = { for k, zone in local.pull_zones : k => zone if zone.wildcard }

  pullzone    = bunnynet_pullzone.this[each.key].id
  name        = "*.${each.value.record_name}.${var.domain}"
  tls_enabled = each.value.tls
  force_ssl   = each.value.force_ssl
}

resource "bunnynet_dns_record" "pull_zone_cname" {
  for_each = local.pull_zone_cnames

  zone        = bunnynet_dns_zone.this.id
  name        = each.value.name
  type        = "CNAME"
  value       = bunnynet_pullzone.this[each.value.zone_key].cdn_domain
  accelerated = false
}
