output "zone_id" {
  description = "Bunny.net DNS zone ID"
  value       = bunnynet_dns_zone.this.id
}

output "domain" {
  description = "Domain name of the DNS zone"
  value       = bunnynet_dns_zone.this.domain
}

output "nameserver1" {
  description = "Primary nameserver for the DNS zone"
  value       = bunnynet_dns_zone.this.nameserver1
}

output "nameserver2" {
  description = "Secondary nameserver for the DNS zone"
  value       = bunnynet_dns_zone.this.nameserver2
}

output "dnssec_enabled" {
  description = "Whether DNSSEC is enabled on the Bunny.net DNS zone"
  value       = bunnynet_dns_zone.this.dnssec_enabled
}

output "ds_record" {
  description = <<-EOT
    DS record when DNSSEC is ready (key_id / algorithm / digest with Scaleway-style
    enum strings). Null when DNSSEC is disabled or DS values are not yet published.
  EOT
  value = local.dnssec_ready ? {
    key_id    = bunnynet_dns_zone.this.dnssec_keytag
    algorithm = local.dnssec_algorithm_name
    digest = {
      type   = local.dnssec_digest_type_name
      digest = bunnynet_dns_zone.this.dnssec_digest
    }
  } : null
}

output "a_record_ids" {
  description = "Map of A record keys to Bunny.net record IDs"
  value       = { for k, r in bunnynet_dns_record.a : k => r.id }
}

output "cname_record_ids" {
  description = "Map of CNAME record keys to Bunny.net record IDs"
  value       = { for k, r in bunnynet_dns_record.cname : k => r.id }
}

output "cdn_pullzone_ids" {
  description = "Map of cdn = true record keys (a/… or cname/…) to Terraform-managed pull zone IDs"
  value       = { for k, z in bunnynet_pullzone.cdn : k => z.id }
}

output "a_cdn_pullzone_ids" {
  description = "Map of A record keys with cdn = true to their Terraform-managed pull zone IDs"
  value = {
    for k, r in bunnynet_dns_record.a : k => bunnynet_pullzone.cdn["a/${k}"].id
    if r.type == "PullZone"
  }
}

output "cname_cdn_pullzone_ids" {
  description = "Map of CNAME record keys with cdn = true to their Terraform-managed pull zone IDs"
  value = {
    for k, r in bunnynet_dns_record.cname : k => bunnynet_pullzone.cdn["cname/${k}"].id
    if r.type == "PullZone"
  }
}

output "a_shield_ids" {
  description = "Map of CDN A-record pull zones with Bunny Shield enabled to their Shield IDs"
  value = {
    for k, r in bunnynet_pullzone_shield.cdn : trimprefix(k, "a/") => r.id
    if startswith(k, "a/")
  }
}

output "cname_shield_ids" {
  description = "Map of CDN CNAME-record pull zones with Bunny Shield enabled to their Shield IDs"
  value = {
    for k, r in bunnynet_pullzone_shield.cdn : trimprefix(k, "cname/") => r.id
    if startswith(k, "cname/")
  }
}

output "pull_zone_shield_ids" {
  description = "Map of pull zone names with Bunny Shield enabled to their Shield IDs"
  value       = { for k, r in bunnynet_pullzone_shield.pull_zone : k => r.id }
}

output "pull_zone_ids" {
  description = "Map of pull zone names to Bunny pull zone IDs"
  value       = { for k, z in bunnynet_pullzone.this : k => z.id }
}

output "pull_zone_cdn_domains" {
  description = "Map of pull zone names to the hostname their records CNAME to"
  value       = { for k, z in bunnynet_pullzone.this : k => "${z.name}.${z.cdn_domain}" }
}

output "txt_record_ids" {
  description = "Map of TXT record keys to Bunny.net record IDs"
  value       = { for k, r in bunnynet_dns_record.txt : k => r.id }
}

output "mx_record_ids" {
  description = "Map of MX record keys to Bunny.net record IDs"
  value       = { for k, r in bunnynet_dns_record.mx : k => r.id }
}
