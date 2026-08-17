# Desired DNSSEC state: non-null var.dnssec enables with that DS; null disables.
# The scaleway_domain_registration resource cannot set a custom DS (computed-only),
# so we call the registrar API:
# POST /domain/v2beta1/domains/{domain}/enable-dnssec|disable-dnssec
locals {
  dnssec_enabled = var.dnssec != null
}

resource "null_resource" "dnssec" {
  depends_on = [scaleway_domain_registration.this]

  triggers = {
    domain         = var.domain
    dnssec_enabled = tostring(local.dnssec_enabled)
    ds_record      = local.dnssec_enabled ? jsonencode(var.dnssec) : ""
  }

  provisioner "local-exec" {
    when = create
    environment = {
      SCW_DOMAIN         = self.triggers.domain
      SCW_DNSSEC_ENABLED = self.triggers.dnssec_enabled
      # triggers.ds_record is jsonencode(var.dnssec); wrap for the API body.
      SCW_DS_JSON = self.triggers.ds_record != "" ? "{\"ds_record\":${self.triggers.ds_record}}" : ""
    }
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      : "$${SCW_SECRET_KEY:?SCW_SECRET_KEY must be set in the environment}"
      if [ "$${SCW_DNSSEC_ENABLED}" = "true" ]; then
        curl -fsS -X POST \
          "https://api.scaleway.com/domain/v2beta1/domains/$${SCW_DOMAIN}/enable-dnssec" \
          -H "X-Auth-Token: $${SCW_SECRET_KEY}" \
          -H "Content-Type: application/json" \
          -d "$${SCW_DS_JSON}"
      else
        curl -fsS -X POST \
          "https://api.scaleway.com/domain/v2beta1/domains/$${SCW_DOMAIN}/disable-dnssec" \
          -H "X-Auth-Token: $${SCW_SECRET_KEY}" \
          -H "Content-Type: application/json" \
          -d '{}' || true
      fi
    EOT
  }

  provisioner "local-exec" {
    when = destroy
    environment = {
      SCW_DOMAIN = self.triggers.domain
    }
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      : "$${SCW_SECRET_KEY:?SCW_SECRET_KEY must be set in the environment}"
      curl -fsS -X POST \
        "https://api.scaleway.com/domain/v2beta1/domains/$${SCW_DOMAIN}/disable-dnssec" \
        -H "X-Auth-Token: $${SCW_SECRET_KEY}" \
        -H "Content-Type: application/json" \
        -d '{}' || true
    EOT
  }
}
