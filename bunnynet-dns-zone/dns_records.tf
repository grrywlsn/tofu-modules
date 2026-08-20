locals {
  a_records = {
    for idx, record in var.a_records :
    "${record.name != "" ? record.name : "@"}-${record.value}-${idx}" => merge(record, {
      shield     = record.cdn && coalesce(record.shield, true)
      edge_rules = record.cdn ? coalesce(record.edge_rules, var.cdn_edge_rules) : []
    })
  }

  cname_records = {
    for idx, record in var.cname_records :
    "${record.name != "" ? record.name : "@"}-${record.value}-${idx}" => merge(record, {
      shield     = record.cdn && coalesce(record.shield, true)
      edge_rules = record.cdn ? coalesce(record.edge_rules, var.cdn_edge_rules) : []
    })
  }

  cdn_records = merge(
    {
      for k, record in local.a_records : "a/${k}" => merge(record, {
        kind = "a"
        key  = k
      }) if record.cdn
    },
    {
      for k, record in local.cname_records : "cname/${k}" => merge(record, {
        kind = "cname"
        key  = k
      }) if record.cdn
    },
  )

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
  type        = each.value.cdn ? "PullZone" : "A"
  value       = each.value.cdn ? bunnynet_pullzone.cdn["a/${each.key}"].name : each.value.value
  ttl         = each.value.ttl
  accelerated = false
  pullzone_id = each.value.cdn ? bunnynet_pullzone.cdn["a/${each.key}"].id : null
}

resource "bunnynet_dns_record" "cname" {
  for_each = local.cname_records

  zone        = bunnynet_dns_zone.this.id
  name        = each.value.name
  type        = each.value.cdn ? "PullZone" : "CNAME"
  value       = each.value.cdn ? bunnynet_pullzone.cdn["cname/${each.key}"].name : each.value.value
  ttl         = each.value.ttl
  accelerated = false
  pullzone_id = each.value.cdn ? bunnynet_pullzone.cdn["cname/${each.key}"].id : null
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
