locals {
  cdn_shield_records = {
    for k, record in local.cdn_records : k => record
    if record.shield
  }

  pull_zone_shields = {
    for k, zone in local.pull_zones : k => zone
    if zone.shield
  }
}

resource "bunnynet_pullzone_shield" "cdn" {
  for_each = local.cdn_shield_records

  pullzone = bunnynet_pullzone.cdn[each.key].id
  tier     = var.shield.tier

  ddos {
    level = var.shield.ddos_level
  }

  waf {
    enabled = var.shield.waf
    mode    = var.shield.waf_mode
  }
}

resource "bunnynet_pullzone_shield" "pull_zone" {
  for_each = local.pull_zone_shields

  pullzone = bunnynet_pullzone.this[each.key].id
  tier     = var.shield.tier

  ddos {
    level = var.shield.ddos_level
  }

  waf {
    enabled = var.shield.waf
    mode    = var.shield.waf_mode
  }
}
