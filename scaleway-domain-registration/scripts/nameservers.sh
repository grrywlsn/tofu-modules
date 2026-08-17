#!/usr/bin/env bash
# Manage Scaleway root-zone nameservers to match NAMESERVERS (comma-separated).
set -euo pipefail

if [ -z "${SCW_SECRET_KEY:-}" ] && command -v scw >/dev/null 2>&1; then
  SCW_SECRET_KEY="$(scw config get secret-key 2>/dev/null || true)"
fi
: "${SCW_SECRET_KEY:?SCW_SECRET_KEY must be set (env or scw config)}"

dns_zone="${DNS_ZONE:?DNS_ZONE is required}"

list_nameservers_csv() {
  local raw
  if command -v scw >/dev/null 2>&1; then
    raw="$(scw dns record list-nameservers dns-zone="${dns_zone}" -o json)"
  else
    raw="$(curl -fsS \
      "https://api.scaleway.com/domain/v2beta1/dns-zones/${dns_zone}/nameservers" \
      -H "X-Auth-Token: ${SCW_SECRET_KEY}")"
  fi
  if command -v jq >/dev/null 2>&1; then
    jq -r '[.ns[].name | sub("\\.$"; "")] | join(",")' <<<"${raw}"
  else
    printf '%s' "${raw}" | sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | sed 's/\.$//' | paste -sd, -
  fi
}

set_nameservers() {
  local -a ns_list=()
  IFS=',' read -r -a ns_list <<< "${NAMESERVERS:?NAMESERVERS is required}"
  if [ "${#ns_list[@]}" -lt 2 ]; then
    echo "NAMESERVERS must contain at least two hostnames" >&2
    exit 1
  fi

  if command -v scw >/dev/null 2>&1; then
    local -a args=()
    local i
    for i in "${!ns_list[@]}"; do
      args+=("ns.${i}.name=${ns_list[$i]}")
    done
    scw dns record update-nameservers "${dns_zone}" "${args[@]}" >/dev/null
    return
  fi

  local json='{"ns":['
  local i
  for i in "${!ns_list[@]}"; do
    [ "${i}" -gt 0 ] && json+=','
    json+="{\"name\":\"${ns_list[$i]}\",\"ip\":[]}"
  done
  json+=']}'

  curl -fsS -X PUT \
    "https://api.scaleway.com/domain/v2beta1/dns-zones/${dns_zone}/nameservers" \
    -H "X-Auth-Token: ${SCW_SECRET_KEY}" \
    -H "Content-Type: application/json" \
    -d "${json}" >/dev/null
}

emit_state() {
  local names
  names="$(list_nameservers_csv)"
  printf '{"dns_zone":"%s","nameservers":"%s"}\n' "${dns_zone}" "${names}"
}

action="${1:?action required}"
case "${action}" in
  read)
    emit_state
    ;;
  create|update)
    # With a read lifecycle, create/update must not print state JSON.
    set_nameservers
    ;;
  delete)
    # Leave registrar NS in place on destroy; only stop managing them.
    printf '{}\n'
    ;;
  *)
    echo "unknown action: ${action}" >&2
    exit 1
    ;;
esac
