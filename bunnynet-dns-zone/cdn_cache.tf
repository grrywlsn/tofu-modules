locals {
  a_cdn_cache_records = {
    for k, record in local.a_records : k => record
    if record.cdn && record.cache_expiration_time != null
  }

  cname_cdn_cache_records = {
    for k, record in local.cname_records : k => record
    if record.cdn && record.cache_expiration_time != null
  }
}

# CDN Acceleration auto-creates a pull zone; override GET cache TTL via an edge rule.
resource "bunnynet_pullzone_edgerule" "a_cache_get" {
  for_each = local.a_cdn_cache_records

  enabled     = true
  pullzone    = bunnynet_dns_record.a[each.key].accelerated_pullzone
  description = "Override cache time for GET requests"
  match_type  = "MatchAny"

  actions = [
    {
      type       = "OverrideCacheTime"
      parameter1 = tostring(each.value.cache_expiration_time)
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

resource "bunnynet_pullzone_edgerule" "cname_cache_get" {
  for_each = local.cname_cdn_cache_records

  enabled     = true
  pullzone    = bunnynet_dns_record.cname[each.key].accelerated_pullzone
  description = "Override cache time for GET requests"
  match_type  = "MatchAny"

  actions = [
    {
      type       = "OverrideCacheTime"
      parameter1 = tostring(each.value.cache_expiration_time)
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
