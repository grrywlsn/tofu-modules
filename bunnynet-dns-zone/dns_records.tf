locals {
  # Merge module cdn_cache defaults with optional per-record overrides.
  # Unset optional fields are null and inherit; empty lists / 0 disable that rule.
  # coalesce alone cannot express "both null" (module disables anonymous GET),
  # so cache_expiration_time uses an explicit null-aware pick.
  effective_cdn_cache = {
    for pair in concat(
      [for idx, r in var.a_records : { key = "a-${idx}", record = r }],
      [for idx, r in var.cname_records : { key = "cname-${idx}", record = r }],
    ) :
    pair.key => {
      cache_expiration_time = (
        try(pair.record.cdn_cache.cache_expiration_time, null) != null
        ? pair.record.cdn_cache.cache_expiration_time
        : var.cdn_cache.cache_expiration_time
      )
      browser_cache_expiration_time = coalesce(
        try(pair.record.cdn_cache.browser_cache_expiration_time, null),
        var.cdn_cache.browser_cache_expiration_time
      )
      override_browser_cache = coalesce(
        try(pair.record.cdn_cache.override_browser_cache, null),
        var.cdn_cache.override_browser_cache
      )
      bypass_authorization = coalesce(
        try(pair.record.cdn_cache.bypass_authorization, null),
        var.cdn_cache.bypass_authorization
      )
      bypass_cookie_patterns = coalesce(
        try(pair.record.cdn_cache.bypass_cookie_patterns, null),
        var.cdn_cache.bypass_cookie_patterns
      )
      bypass_url_patterns = coalesce(
        try(pair.record.cdn_cache.bypass_url_patterns, null),
        var.cdn_cache.bypass_url_patterns
      )
    }
    if pair.record.cdn
  }

  a_records = {
    for idx, record in var.a_records :
    "${record.name != "" ? record.name : "@"}-${record.value}-${idx}" => merge(record, {
      shield    = record.cdn && coalesce(record.shield, true)
      cdn_cache = record.cdn ? local.effective_cdn_cache["a-${idx}"] : null
    })
  }

  cname_records = {
    for idx, record in var.cname_records :
    "${record.name != "" ? record.name : "@"}-${record.value}-${idx}" => merge(record, {
      shield    = record.cdn && coalesce(record.shield, true)
      cdn_cache = record.cdn ? local.effective_cdn_cache["cname-${idx}"] : null
    })
  }

  txt_records = {
    for idx, record in var.txt_records :
    "${record.name != "" ? record.name : "@"}-${record.value}-${idx}" => record
  }

  mx_records = {
    for idx, record in var.mx_records :
    "${record.name != "" ? record.name : "@"}-${record.priority}-${record.value}-${idx}" => record
  }
}

resource "bunnynet_dns_record" "a" {
  for_each = local.a_records

  zone        = bunnynet_dns_zone.this.id
  name        = each.value.name
  type        = "A"
  value       = each.value.value
  ttl         = each.value.ttl
  accelerated = each.value.cdn
}

resource "bunnynet_dns_record" "cname" {
  for_each = local.cname_records

  zone        = bunnynet_dns_zone.this.id
  name        = each.value.name
  type        = "CNAME"
  value       = each.value.value
  ttl         = each.value.ttl
  accelerated = each.value.cdn
}

resource "bunnynet_dns_record" "txt" {
  for_each = local.txt_records

  zone  = bunnynet_dns_zone.this.id
  name  = each.value.name
  type  = "TXT"
  value = each.value.value
  ttl   = each.value.ttl
}

resource "bunnynet_dns_record" "mx" {
  for_each = local.mx_records

  zone     = bunnynet_dns_zone.this.id
  name     = each.value.name
  type     = "MX"
  value    = each.value.value
  priority = each.value.priority
  ttl      = each.value.ttl
}
