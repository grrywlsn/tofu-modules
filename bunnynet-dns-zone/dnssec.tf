locals {
  # IANA DNSSEC algorithm numbers → Scaleway registrar enum strings
  # https://www.iana.org/assignments/dns-sec-alg-numbers/dns-sec-alg-numbers.xhtml
  dnssec_algorithm_names = {
    "5"  = "rsasha1"
    "7"  = "rsasha1_nsec3_sha1"
    "8"  = "rsasha256"
    "10" = "rsasha512"
    "13" = "ecdsap256sha256"
    "14" = "ecdsap384sha384"
    "15" = "ed25519"
    "16" = "ed448"
  }

  # IANA DS digest types → Scaleway registrar enum strings
  # https://www.iana.org/assignments/ds-rr-types/ds-rr-types.xhtml
  dnssec_digest_type_names = {
    "1" = "sha_1"
    "2" = "sha_256"
    "3" = "gost_r_34_11_94"
    "4" = "sha_384"
  }

  dnssec_algorithm_name = try(
    local.dnssec_algorithm_names[tostring(bunnynet_dns_zone.this.dnssec_algorithm)],
    null,
  )
  dnssec_digest_type_name = try(
    local.dnssec_digest_type_names[tostring(bunnynet_dns_zone.this.dnssec_digest_type)],
    null,
  )

  dnssec_ready = (
    var.dnssec_enabled &&
    bunnynet_dns_zone.this.dnssec_enabled &&
    try(bunnynet_dns_zone.this.dnssec_keytag, 0) != 0 &&
    try(bunnynet_dns_zone.this.dnssec_digest, "") != "" &&
    local.dnssec_algorithm_name != null &&
    local.dnssec_digest_type_name != null
  )
}
