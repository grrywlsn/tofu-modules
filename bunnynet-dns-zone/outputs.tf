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
    DS record shaped for scaleway-domain-registration's ds_record input
    (key_id / algorithm / digest). Null when DNSSEC is disabled or Bunny has
    not yet published DS values.
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

output "a_cdn_pullzone_ids" {
  description = "Map of A record keys with cdn = true to their Bunny CDN Acceleration pull zone IDs"
  value = {
    for k, r in bunnynet_dns_record.a : k => r.accelerated_pullzone
    if r.accelerated
  }
}

output "cname_cdn_pullzone_ids" {
  description = "Map of CNAME record keys with cdn = true to their Bunny CDN Acceleration pull zone IDs"
  value = {
    for k, r in bunnynet_dns_record.cname : k => r.accelerated_pullzone
    if r.accelerated
  }
}

output "a_shield_ids" {
  description = "Map of A record keys with Bunny Shield enabled to their Shield IDs"
  value       = { for k, r in bunnynet_pullzone_shield.a : k => r.id }
}

output "cname_shield_ids" {
  description = "Map of CNAME record keys with Bunny Shield enabled to their Shield IDs"
  value       = { for k, r in bunnynet_pullzone_shield.cname : k => r.id }
}

output "txt_record_ids" {
  description = "Map of TXT record keys to Bunny.net record IDs"
  value       = { for k, r in bunnynet_dns_record.txt : k => r.id }
}

output "mx_record_ids" {
  description = "Map of MX record keys to Bunny.net record IDs"
  value       = { for k, r in bunnynet_dns_record.mx : k => r.id }
}
