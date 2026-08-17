locals {
  a_shield_records = {
    for k, record in local.a_records : k => record
    if record.shield
  }

  cname_shield_records = {
    for k, record in local.cname_records : k => record
    if record.shield
  }
}

resource "bunnynet_pullzone_shield" "a" {
  for_each = local.a_shield_records

  pullzone = bunnynet_dns_record.a[each.key].accelerated_pullzone
  tier     = var.shield.tier

  ddos {
    level = var.shield.ddos_level
  }

  waf {
    enabled = var.shield.waf
    mode    = var.shield.waf_mode
  }
}

resource "bunnynet_pullzone_shield" "cname" {
  for_each = local.cname_shield_records

  pullzone = bunnynet_dns_record.cname[each.key].accelerated_pullzone
  tier     = var.shield.tier

  ddos {
    level = var.shield.ddos_level
  }

  waf {
    enabled = var.shield.waf
    mode    = var.shield.waf_mode
  }
}
