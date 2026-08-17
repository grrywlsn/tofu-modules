# Linked root DNS zone for the registered domain (created with the registration).
# The Scaleway provider cannot set zone nameservers; this module keeps them equal
# to var.nameservers via the DNS API (declarative create/read/update).
# Revisit if the provider gains writable NS on scaleway_domain_zone.
locals {
  nameservers_normalized = var.nameservers == null ? [] : [
    for ns in var.nameservers : trimsuffix(ns, ".")
  ]
  nameservers_csv = join(",", local.nameservers_normalized)
}

data "scaleway_domain_zone" "root" {
  count = var.nameservers != null ? 1 : 0

  domain    = var.domain
  subdomain = ""

  depends_on = [scaleway_domain_registration.this]
}

resource "shell_script" "root_nameservers" {
  count = var.nameservers != null ? 1 : 0

  lifecycle_commands {
    create = "bash ${path.module}/scripts/nameservers.sh create"
    read   = "bash ${path.module}/scripts/nameservers.sh read"
    update = "bash ${path.module}/scripts/nameservers.sh update"
    delete = "bash ${path.module}/scripts/nameservers.sh delete"
  }

  interpreter = ["/bin/bash", "-c"]

  environment = {
    # Root zone name for the registered domain (same as domain for subdomain "").
    DNS_ZONE    = var.domain
    NAMESERVERS = local.nameservers_csv
  }

  triggers = {
    nameservers = local.nameservers_csv
  }

  depends_on = [
    scaleway_domain_registration.this,
    data.scaleway_domain_zone.root,
  ]
}
