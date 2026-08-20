locals {
  # Bunny rejects more than 5 patterns in a single edge-rule condition.
  cdn_edge_rule_max_patterns = 5

  # Rules grouped by the resource that owns the pull zone they attach to.
  edge_rule_sets = {
    cdn      = { for k, record in local.cdn_records : k => record.edge_rules }
    pullzone = { for k, zone in local.pull_zones : k => zone.edge_rules }
  }

  # Expand caller-provided rules: single-trigger rules with >5 patterns are split
  # into consecutive priorities so they stay within Bunny's limit.
  edge_rules = {
    for set_name, rules_by_owner in local.edge_rule_sets : set_name => {
      for item in flatten([
        for record_key, rules in rules_by_owner : [
          for rule_idx, rule in rules : (
            length(rule.triggers) == 1 && length(rule.triggers[0].patterns) > local.cdn_edge_rule_max_patterns
            ? [
              for chunk_idx, patterns in chunklist(rule.triggers[0].patterns, local.cdn_edge_rule_max_patterns) : {
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
  }
}

resource "bunnynet_pullzone_edgerule" "cdn" {
  for_each = local.edge_rules.cdn

  enabled     = each.value.enabled
  pullzone    = bunnynet_pullzone.cdn[each.value.record_key].id
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

resource "bunnynet_pullzone_edgerule" "pull_zone" {
  for_each = local.edge_rules.pullzone

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
