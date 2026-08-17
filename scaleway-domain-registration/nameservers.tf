# The scaleway_domain_registration resource cannot set zone nameservers.
# Delegate via PUT /domain/v2beta1/dns-zones/{domain}/nameservers when
# var.nameservers is set. Revisit if the provider gains NS support.
locals {
  nameservers_normalized = var.nameservers == null ? [] : [
    for ns in var.nameservers : trimsuffix(ns, ".")
  ]
}

resource "terraform_data" "nameservers" {
  count = var.nameservers != null ? 1 : 0

  depends_on = [scaleway_domain_registration.this]

  input = {
    domain      = var.domain
    nameservers = join(",", local.nameservers_normalized)
  }

  provisioner "local-exec" {
    when = create
    environment = {
      SCW_DOMAIN      = self.input.domain
      SCW_NAMESERVERS = self.input.nameservers
    }
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail

      if [ -z "$${SCW_SECRET_KEY:-}" ] && command -v scw >/dev/null 2>&1; then
        SCW_SECRET_KEY="$(scw config get secret-key 2>/dev/null || true)"
      fi
      : "$${SCW_SECRET_KEY:?SCW_SECRET_KEY must be set (env or scw config) — same key the Scaleway provider uses}"

      IFS=',' read -r -a ns_list <<< "$${SCW_NAMESERVERS}"
      if [ "$${#ns_list[@]}" -lt 2 ]; then
        echo "nameservers must contain at least two entries" >&2
        exit 1
      fi

      if command -v scw >/dev/null 2>&1; then
        args=()
        for i in "$${!ns_list[@]}"; do
          args+=("ns.$${i}.name=$${ns_list[$i]}")
        done
        scw dns record update-nameservers "$${SCW_DOMAIN}" "$${args[@]}"
        exit 0
      fi

      json='{"ns":['
      for i in "$${!ns_list[@]}"; do
        [ "$${i}" -gt 0 ] && json+=','
        json+="{\"name\":\"$${ns_list[$i]}\",\"ip\":[]}"
      done
      json+=']}'

      tmp="$(mktemp)"
      http="$(curl -sS -o "$${tmp}" -w "%{http_code}" -X PUT \
        "https://api.scaleway.com/domain/v2beta1/dns-zones/$${SCW_DOMAIN}/nameservers" \
        -H "X-Auth-Token: $${SCW_SECRET_KEY}" \
        -H "Content-Type: application/json" \
        -d "$${json}")"
      if [ "$${http}" -lt 200 ] || [ "$${http}" -ge 300 ]; then
        echo "Scaleway API PUT /dns-zones/$${SCW_DOMAIN}/nameservers failed (HTTP $${http}):" >&2
        cat "$${tmp}" >&2 || true
        echo >&2
        rm -f "$${tmp}"
        exit 1
      fi
      cat "$${tmp}"
      rm -f "$${tmp}"
    EOT
  }
}
