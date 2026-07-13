locals {
  a_records = {
    for idx, record in var.a_records :
    "${record.name != "" ? record.name : "@"}-${record.value}-${idx}" => record
  }

  cname_records = {
    for idx, record in var.cname_records :
    "${record.name}-${record.value}-${idx}" => record
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

  zone  = bunnynet_dns_zone.this.id
  name  = each.value.name
  type  = "A"
  value = each.value.value
  ttl   = each.value.ttl
}

resource "bunnynet_dns_record" "cname" {
  for_each = local.cname_records

  zone  = bunnynet_dns_zone.this.id
  name  = each.value.name
  type  = "CNAME"
  value = each.value.value
  ttl   = each.value.ttl
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
