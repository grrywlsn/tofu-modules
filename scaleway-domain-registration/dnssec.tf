# Desired DNSSEC state comes from dnssec_enabled + dnssec_ds_record.
# The scaleway_domain_registration resource cannot set a custom DS (computed-only),
# so we call the registrar API:
# POST /domain/v2beta1/domains/{domain}/enable-dnssec|disable-dnssec
resource "null_resource" "dnssec" {
  depends_on = [scaleway_domain_registration.this]

  triggers = {
    domain         = var.domain
    dnssec_enabled = tostring(var.dnssec_enabled)
    ds_record      = var.dnssec_enabled ? jsonencode(var.dnssec_ds_record) : ""
  }

  provisioner "local-exec" {
    when = create
    environment = {
      SCW_DOMAIN         = self.triggers.domain
      SCW_DNSSEC_ENABLED = self.triggers.dnssec_enabled
      # triggers.ds_record is jsonencode(var.dnssec_ds_record); wrap for the API body.
      SCW_DS_JSON = self.triggers.ds_record != "" ? "{\"ds_record\":${self.triggers.ds_record}}" : ""
    }
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail

      # Match Scaleway provider credential resolution: env, then CLI config.
      if [ -z "$${SCW_SECRET_KEY:-}" ] && command -v scw >/dev/null 2>&1; then
        SCW_SECRET_KEY="$(scw config get secret-key 2>/dev/null || true)"
      fi
      : "$${SCW_SECRET_KEY:?SCW_SECRET_KEY must be set (env or scw config) — same key the Scaleway provider uses}"

      scw_api() {
        local method="$1" path="$2" body="$3"
        local tmp http
        tmp="$(mktemp)"
        http="$(curl -sS -o "$${tmp}" -w "%{http_code}" -X "$${method}" \
          "https://api.scaleway.com$${path}" \
          -H "X-Auth-Token: $${SCW_SECRET_KEY}" \
          -H "Content-Type: application/json" \
          -d "$${body}")"
        if [ "$${http}" -lt 200 ] || [ "$${http}" -ge 300 ]; then
          echo "Scaleway API $${method} $${path} failed (HTTP $${http}):" >&2
          cat "$${tmp}" >&2 || true
          echo >&2
          rm -f "$${tmp}"
          return 1
        fi
        cat "$${tmp}"
        rm -f "$${tmp}"
      }

      if [ "$${SCW_DNSSEC_ENABLED}" = "true" ]; then
        scw_api POST "/domain/v2beta1/domains/$${SCW_DOMAIN}/enable-dnssec" "$${SCW_DS_JSON}"
      else
        scw_api POST "/domain/v2beta1/domains/$${SCW_DOMAIN}/disable-dnssec" '{}' || true
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
      if [ -z "$${SCW_SECRET_KEY:-}" ] && command -v scw >/dev/null 2>&1; then
        SCW_SECRET_KEY="$(scw config get secret-key 2>/dev/null || true)"
      fi
      : "$${SCW_SECRET_KEY:?SCW_SECRET_KEY must be set (env or scw config)}"
      curl -sS -o /dev/null -w "%{http_code}" -X POST \
        "https://api.scaleway.com/domain/v2beta1/domains/$${SCW_DOMAIN}/disable-dnssec" \
        -H "X-Auth-Token: $${SCW_SECRET_KEY}" \
        -H "Content-Type: application/json" \
        -d '{}' >/dev/null || true
    EOT
  }
}
