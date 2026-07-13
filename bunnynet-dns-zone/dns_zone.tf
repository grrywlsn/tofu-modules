resource "bunnynet_dns_zone" "this" {
  domain         = var.domain
  dnssec_enabled = var.dnssec_enabled
}
