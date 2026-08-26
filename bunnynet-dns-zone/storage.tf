resource "bunnynet_storage_zone" "this" {
  for_each = var.storage_zones

  name                 = each.key
  region               = each.value.region
  zone_tier            = each.value.zone_tier
  replication_regions  = length(each.value.replication_regions) > 0 ? each.value.replication_regions : null
  custom_404_file_path = each.value.custom_404_file_path
  rewrite_404_to_200   = each.value.rewrite_404_to_200
}
