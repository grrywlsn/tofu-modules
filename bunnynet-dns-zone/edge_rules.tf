locals {
  # Bunny rejects more than 5 patterns in a single edge-rule condition.
  edge_rule_max_patterns = 5

  # ACME HTTP-01 challenge paths must never be served from the edge cache: a
  # pinned stale/wrong response for a challenge token fails LE validation for
  # up to the cache TTL. Match both the bare path and anything under it.
  acme_challenge_patterns = [
    "*/.well-known/acme-challenge",
    "*/.well-known/acme-challenge/*",
  ]

  # Module-default ACME bypass rule per pull zone. Injected unless the caller
  # set acme_challenge_cache_bypass = false or already has a Url rule matching
  # an acme-challenge pattern. The priority sits just below the lowest
  # caller-supplied rule so the bypass always evaluates before any cache rule.
  acme_bypass_rules = {
    for record_key, zone in var.pullzone_records : "${record_key}/acme/0" => {
      key         = "${record_key}/acme/0"
      record_key  = record_key
      description = "Bypass edge cache for ACME HTTP-01 challenges (module default)"
      enabled     = true
      match_type  = "MatchAny"
      priority    = max(min(concat([for r in zone.edge_rules : r.priority], [1000])...) - 1, 1)
      actions = [{
        type       = "OverrideCacheTime"
        parameter1 = "0"
        parameter2 = null
        parameter3 = null
      }]
      triggers = [{
        type       = "Url"
        match_type = "MatchAny"
        patterns   = local.acme_challenge_patterns
        parameter1 = null
        parameter2 = null
      }]
    }
    if coalesce(zone.acme_challenge_cache_bypass, true) && !anytrue([
      for rule in zone.edge_rules : anytrue([
        for t in rule.triggers : t.type == "Url" && anytrue([
          for p in t.patterns : can(regex("acme-challenge", p))
        ])
      ])
    ])
  }

  # Expand caller-provided rules: single-trigger rules with >5 patterns are split
  # into consecutive priorities so they stay within Bunny's limit.
  caller_edge_rules = {
    for item in flatten([
      for record_key, zone in var.pullzone_records : [
        for rule_idx, rule in zone.edge_rules : (
          length(rule.triggers) == 1 && length(rule.triggers[0].patterns) > local.edge_rule_max_patterns
          ? [
            for chunk_idx, patterns in chunklist(rule.triggers[0].patterns, local.edge_rule_max_patterns) : {
              key         = "${record_key}/${rule_idx}/${chunk_idx}"
              record_key  = record_key
              description = rule.description
              enabled     = rule.enabled
              match_type  = rule.match_type
              priority    = rule.priority + chunk_idx
              actions     = rule.actions
              triggers = [{
                type       = rule.triggers[0].type
                match_type = rule.triggers[0].match_type
                patterns   = patterns
                parameter1 = rule.triggers[0].parameter1
                parameter2 = rule.triggers[0].parameter2
              }]
            }
          ]
          : [{
            key         = "${record_key}/${rule_idx}/0"
            record_key  = record_key
            description = rule.description
            enabled     = rule.enabled
            match_type  = rule.match_type
            priority    = rule.priority
            actions     = rule.actions
            triggers    = rule.triggers
          }]
        )
      ]
    ]) : item.key => item
  }

  # Caller rules plus the module-default ACME bypass rules. The "acme" key
  # segment never collides with caller keys ("<zone>/<rule_idx>/<chunk_idx>").
  edge_rules = merge(local.caller_edge_rules, local.acme_bypass_rules)
}

resource "bunnynet_pullzone_edgerule" "this" {
  for_each = local.edge_rules

  enabled     = each.value.enabled
  pullzone    = bunnynet_pullzone.this[each.value.record_key].id
  description = each.value.description
  match_type  = each.value.match_type
  priority    = each.value.priority

  actions = [
    for action in each.value.actions : {
      type       = action.type
      parameter1 = action.parameter1
      parameter2 = action.parameter2
      parameter3 = action.parameter3
    }
  ]

  triggers = [
    for trigger in each.value.triggers : {
      type       = trigger.type
      match_type = trigger.match_type
      patterns   = trigger.patterns
      parameter1 = trigger.parameter1
      parameter2 = trigger.parameter2
    }
  ]
}
