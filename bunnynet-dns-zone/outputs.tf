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

output "txt_record_ids" {
  description = "Map of TXT record keys to Bunny.net record IDs"
  value       = { for k, r in bunnynet_dns_record.txt : k => r.id }
}

output "mx_record_ids" {
  description = "Map of MX record keys to Bunny.net record IDs"
  value       = { for k, r in bunnynet_dns_record.mx : k => r.id }
}

output "pull_zone_ids" {
  description = "Map of pull zone names to Bunny pull zone IDs"
  value       = { for k, z in bunnynet_pullzone.this : k => z.id }
}

output "pull_zone_cdn_domains" {
  description = "Map of pull zone names to the hostname their records CNAME to"
  value       = { for k, z in bunnynet_pullzone.this : k => "${z.name}.${z.cdn_domain}" }
}

output "pull_zone_hostname_ids" {
  description = "Map of attached FQDNs to pull zone hostname IDs"
  value       = { for k, h in bunnynet_pullzone_hostname.this : k => h.id }
}

output "pullzone_hostnames" {
  description = "Every hostname this module attaches to a pull zone, mapped to the pull zone serving it"
  value       = { for k, h in bunnynet_pullzone_hostname.this : h.name => bunnynet_pullzone.this[local.pull_zone_host_records[k].zone_key].name }
}

output "pull_zone_shield_ids" {
  description = "Map of pull zone names with Bunny Shield enabled to their Shield IDs"
  value       = { for k, r in bunnynet_pullzone_shield.this : k => r.id }
}
