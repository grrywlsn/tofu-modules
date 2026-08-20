locals {
  cdn_pullzone_name_candidates = {
    for k, record in local.cdn_records : k => replace(replace(replace(
      lower("${var.domain}-${record.name == "" ? "apex" : record.name}"),
      ".", "-"
    ), "*", "star"), "_", "-")
  }

  cdn_pullzone_names = {
    for k, name in local.cdn_pullzone_name_candidates : k => (
      length(name) <= 40 ? name : "cdn-${substr(sha256("${var.domain}/${k}"), 0, 12)}"
    )
  }

  cdn_hostnames = {
    for k, record in local.cdn_records : k => (
      record.name != "" ? "${record.name}.${var.domain}" : var.domain
    ) if record.create_hostname
  }
}

resource "bunnynet_pullzone" "cdn" {
  for_each = local.cdn_records

  name = local.cdn_pullzone_names[each.key]

  origin {
    type = "OriginUrl"
    url = (
      startswith(each.value.value, "http://") || startswith(each.value.value, "https://")
      ? each.value.value
      : (each.value.origin_http ? "http://${each.value.value}" : "https://${each.value.value}")
    )
    forward_host_header = each.value.forward_host_header
    verify_ssl          = each.value.verify_ssl
    follow_redirects    = true
  }

  cache_vary                 = toset(each.value.cache_vary)
  cache_stale                = toset(each.value.cache_stale)
  cache_chunked              = each.value.cache_chunked
  cache_expiration_time      = each.value.cache_expiration_time
  cache_enabled              = each.value.smart_cache
  strip_cookies              = each.value.strip_cookies
  block_no_referer           = each.value.block_no_referer
  use_background_update      = each.value.use_background_update
  request_coalescing_enabled = each.value.request_coalescing_enabled
  request_coalescing_timeout = each.value.request_coalescing_timeout

  routing {
    tier = "Standard"
  }
}

# A PullZone DNS record points the name at Bunny's edge but does not register it
# on the pull zone, and the edge routes by Host: without this the hostname is
# answered with a 403 and the fallback b-cdn.net certificate.
resource "bunnynet_pullzone_hostname" "cdn" {
  for_each = local.cdn_hostnames

  pullzone    = bunnynet_pullzone.cdn[each.key].id
  name        = each.value
  tls_enabled = local.cdn_records[each.key].tls
  force_ssl   = local.cdn_records[each.key].force_ssl

  # Bunny validates that live DNS already resolves to the pull zone.
  depends_on = [
    bunnynet_dns_record.a,
    bunnynet_dns_record.cname,
  ]
}
