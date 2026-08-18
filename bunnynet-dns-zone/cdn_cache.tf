locals {
  a_cdn_records = {
    for k, record in local.a_records : k => record
    if record.cdn
  }

  cname_cdn_records = {
    for k, record in local.cname_records : k => record
    if record.cdn
  }

  # Bunny rejects more than 5 patterns in a single edge-rule condition, so longer
  # bypass lists are split across consecutively prioritised rules.
  cdn_cache_max_patterns = 5

  # Bunny runs edge rules from the lowest priority upwards, and OverrideCacheTime
  # short-circuits on the first match, so bypass rules must sort before caching.
  cdn_cache_priority = {
    bypass_cookie        = 100
    bypass_authorization = 200
    bypass_url           = 300
    cache_get            = 900
    browser_cache_get    = 910
  }

  a_bypass_cookie_rules = {
    for rule in flatten([
      for k, r in local.a_cdn_records : [
        for idx, patterns in chunklist(r.cdn_cache.bypass_cookie_patterns, local.cdn_cache_max_patterns) : {
          key      = "${k}#${idx}"
          record   = k
          index    = idx
          patterns = patterns
        }
      ]
    ]) : rule.key => rule
  }

  a_bypass_url_rules = {
    for rule in flatten([
      for k, r in local.a_cdn_records : [
        for idx, patterns in chunklist(r.cdn_cache.bypass_url_patterns, local.cdn_cache_max_patterns) : {
          key      = "${k}#${idx}"
          record   = k
          index    = idx
          patterns = patterns
        }
      ]
    ]) : rule.key => rule
  }

  cname_bypass_cookie_rules = {
    for rule in flatten([
      for k, r in local.cname_cdn_records : [
        for idx, patterns in chunklist(r.cdn_cache.bypass_cookie_patterns, local.cdn_cache_max_patterns) : {
          key      = "${k}#${idx}"
          record   = k
          index    = idx
          patterns = patterns
        }
      ]
    ]) : rule.key => rule
  }

  cname_bypass_url_rules = {
    for rule in flatten([
      for k, r in local.cname_cdn_records : [
        for idx, patterns in chunklist(r.cdn_cache.bypass_url_patterns, local.cdn_cache_max_patterns) : {
          key      = "${k}#${idx}"
          record   = k
          index    = idx
          patterns = patterns
        }
      ]
    ]) : rule.key => rule
  }
}

# --- A record CDN Acceleration edge rules ---

resource "bunnynet_pullzone_edgerule" "a_bypass_cookie" {
  for_each = local.a_bypass_cookie_rules

  enabled     = true
  pullzone    = bunnynet_dns_record.a[each.value.record].accelerated_pullzone
  description = "Bypass cache when session cookie is present"
  match_type  = "MatchAny"
  priority    = local.cdn_cache_priority.bypass_cookie + each.value.index

  actions = [
    {
      type       = "OverrideCacheTime"
      parameter1 = "0"
      parameter2 = null
      parameter3 = null
    }
  ]

  triggers = [
    {
      type       = "RequestHeader"
      match_type = "MatchAny"
      patterns   = each.value.patterns
      parameter1 = "Cookie"
      parameter2 = null
    }
  ]
}

resource "bunnynet_pullzone_edgerule" "a_bypass_authorization" {
  for_each = {
    for k, r in local.a_cdn_records : k => r
    if r.cdn_cache.bypass_authorization
  }

  enabled     = true
  pullzone    = bunnynet_dns_record.a[each.key].accelerated_pullzone
  description = "Bypass cache when Authorization header is present"
  match_type  = "MatchAny"
  priority    = local.cdn_cache_priority.bypass_authorization

  actions = [
    {
      type       = "OverrideCacheTime"
      parameter1 = "0"
      parameter2 = null
      parameter3 = null
    }
  ]

  triggers = [
    {
      type       = "RequestHeader"
      match_type = "MatchAny"
      patterns   = ["*"]
      parameter1 = "Authorization"
      parameter2 = null
    }
  ]
}

resource "bunnynet_pullzone_edgerule" "a_bypass_url" {
  for_each = local.a_bypass_url_rules

  enabled     = true
  pullzone    = bunnynet_dns_record.a[each.value.record].accelerated_pullzone
  description = "Bypass cache for authenticated paths (${each.value.index + 1})"
  match_type  = "MatchAny"
  priority    = local.cdn_cache_priority.bypass_url + each.value.index

  actions = [
    {
      type       = "OverrideCacheTime"
      parameter1 = "0"
      parameter2 = null
      parameter3 = null
    }
  ]

  triggers = [
    {
      type       = "Url"
      match_type = "MatchAny"
      patterns   = each.value.patterns
      parameter1 = null
      parameter2 = null
    }
  ]
}

resource "bunnynet_pullzone_edgerule" "a_cache_get" {
  for_each = {
    for k, r in local.a_cdn_records : k => r
    if try(r.cdn_cache.cache_expiration_time, 0) > 0
  }

  enabled     = true
  pullzone    = bunnynet_dns_record.a[each.key].accelerated_pullzone
  description = "Cache anonymous GET requests at the edge"
  match_type  = "MatchAny"
  priority    = local.cdn_cache_priority.cache_get

  actions = [
    {
      type       = "OverrideCacheTime"
      parameter1 = tostring(each.value.cdn_cache.cache_expiration_time)
      parameter2 = null
      parameter3 = null
    }
  ]

  triggers = [
    {
      type       = "RequestMethod"
      match_type = "MatchAny"
      patterns   = ["GET"]
      parameter1 = null
      parameter2 = null
    }
  ]
}

resource "bunnynet_pullzone_edgerule" "a_browser_cache_get" {
  for_each = {
    for k, r in local.a_cdn_records : k => r
    if r.cdn_cache.override_browser_cache
  }

  enabled     = true
  pullzone    = bunnynet_dns_record.a[each.key].accelerated_pullzone
  description = "Override browser cache for GET responses"
  match_type  = "MatchAny"
  priority    = local.cdn_cache_priority.browser_cache_get

  actions = [
    {
      type       = "OverrideBrowserCacheTime"
      parameter1 = tostring(each.value.cdn_cache.browser_cache_expiration_time)
      parameter2 = null
      parameter3 = null
    }
  ]

  triggers = [
    {
      type       = "RequestMethod"
      match_type = "MatchAny"
      patterns   = ["GET"]
      parameter1 = null
      parameter2 = null
    }
  ]
}

# --- CNAME record CDN Acceleration edge rules ---

resource "bunnynet_pullzone_edgerule" "cname_bypass_cookie" {
  for_each = local.cname_bypass_cookie_rules

  enabled     = true
  pullzone    = bunnynet_dns_record.cname[each.value.record].accelerated_pullzone
  description = "Bypass cache when session cookie is present"
  match_type  = "MatchAny"
  priority    = local.cdn_cache_priority.bypass_cookie + each.value.index

  actions = [
    {
      type       = "OverrideCacheTime"
      parameter1 = "0"
      parameter2 = null
      parameter3 = null
    }
  ]

  triggers = [
    {
      type       = "RequestHeader"
      match_type = "MatchAny"
      patterns   = each.value.patterns
      parameter1 = "Cookie"
      parameter2 = null
    }
  ]
}

resource "bunnynet_pullzone_edgerule" "cname_bypass_authorization" {
  for_each = {
    for k, r in local.cname_cdn_records : k => r
    if r.cdn_cache.bypass_authorization
  }

  enabled     = true
  pullzone    = bunnynet_dns_record.cname[each.key].accelerated_pullzone
  description = "Bypass cache when Authorization header is present"
  match_type  = "MatchAny"
  priority    = local.cdn_cache_priority.bypass_authorization

  actions = [
    {
      type       = "OverrideCacheTime"
      parameter1 = "0"
      parameter2 = null
      parameter3 = null
    }
  ]

  triggers = [
    {
      type       = "RequestHeader"
      match_type = "MatchAny"
      patterns   = ["*"]
      parameter1 = "Authorization"
      parameter2 = null
    }
  ]
}

resource "bunnynet_pullzone_edgerule" "cname_bypass_url" {
  for_each = local.cname_bypass_url_rules

  enabled     = true
  pullzone    = bunnynet_dns_record.cname[each.value.record].accelerated_pullzone
  description = "Bypass cache for authenticated paths (${each.value.index + 1})"
  match_type  = "MatchAny"
  priority    = local.cdn_cache_priority.bypass_url + each.value.index

  actions = [
    {
      type       = "OverrideCacheTime"
      parameter1 = "0"
      parameter2 = null
      parameter3 = null
    }
  ]

  triggers = [
    {
      type       = "Url"
      match_type = "MatchAny"
      patterns   = each.value.patterns
      parameter1 = null
      parameter2 = null
    }
  ]
}

resource "bunnynet_pullzone_edgerule" "cname_cache_get" {
  for_each = {
    for k, r in local.cname_cdn_records : k => r
    if try(r.cdn_cache.cache_expiration_time, 0) > 0
  }

  enabled     = true
  pullzone    = bunnynet_dns_record.cname[each.key].accelerated_pullzone
  description = "Cache anonymous GET requests at the edge"
  match_type  = "MatchAny"
  priority    = local.cdn_cache_priority.cache_get

  actions = [
    {
      type       = "OverrideCacheTime"
      parameter1 = tostring(each.value.cdn_cache.cache_expiration_time)
      parameter2 = null
      parameter3 = null
    }
  ]

  triggers = [
    {
      type       = "RequestMethod"
      match_type = "MatchAny"
      patterns   = ["GET"]
      parameter1 = null
      parameter2 = null
    }
  ]
}

resource "bunnynet_pullzone_edgerule" "cname_browser_cache_get" {
  for_each = {
    for k, r in local.cname_cdn_records : k => r
    if r.cdn_cache.override_browser_cache
  }

  enabled     = true
  pullzone    = bunnynet_dns_record.cname[each.key].accelerated_pullzone
  description = "Override browser cache for GET responses"
  match_type  = "MatchAny"
  priority    = local.cdn_cache_priority.browser_cache_get

  actions = [
    {
      type       = "OverrideBrowserCacheTime"
      parameter1 = tostring(each.value.cdn_cache.browser_cache_expiration_time)
      parameter2 = null
      parameter3 = null
    }
  ]

  triggers = [
    {
      type       = "RequestMethod"
      match_type = "MatchAny"
      patterns   = ["GET"]
      parameter1 = null
      parameter2 = null
    }
  ]
}
