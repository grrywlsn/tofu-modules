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
