run "acme_bypass_injected_by_default" {
  command = plan

  variables {
    domain = "example.com"
    pullzone_records = {
      app = {
        hostnames  = [""]
        origin_url = "https://origin.example.net"
        edge_rules = [
          {
            description = "Cache anonymous GET requests at the edge"
            priority    = 900
            actions     = [{ type = "OverrideCacheTime", parameter1 = "300" }]
            triggers    = [{ type = "RequestMethod", patterns = ["GET"] }]
          }
        ]
      }
    }
  }

  assert {
    condition = (
      output.pullzone_edge_rules["app/acme/0"].priority == 899 &&
      output.pullzone_edge_rules["app/acme/0"].enabled == true
    )
    error_message = "ACME bypass rule should be enabled at priority 899 (just below the lowest caller rule 900)"
  }

  assert {
    condition = (
      output.pullzone_edge_rules["app/acme/0"].actions[0].type == "OverrideCacheTime" &&
      output.pullzone_edge_rules["app/acme/0"].actions[0].parameter1 == "0"
    )
    error_message = "ACME rule must set OverrideCacheTime 0 (never cache, always pass through to origin)"
  }

  assert {
    condition = (
      output.pullzone_edge_rules["app/acme/0"].triggers[0].type == "Url" &&
      output.pullzone_edge_rules["app/acme/0"].triggers[0].patterns == [
        "*/.well-known/acme-challenge",
        "*/.well-known/acme-challenge/*",
      ]
    )
    error_message = "ACME rule must match the challenge paths"
  }
}

run "acme_bypass_default_priority_without_caller_rules" {
  command = plan

  variables {
    domain = "example.com"
    pullzone_records = {
      app = {
        hostnames  = [""]
        origin_url = "https://origin.example.net"
      }
    }
  }

  assert {
    condition     = output.pullzone_edge_rules["app/acme/0"].priority == 999
    error_message = "with no caller rules the ACME rule should default to priority 999"
  }
}

run "acme_bypass_disabled" {
  command = plan

  variables {
    domain = "example.com"
    pullzone_records = {
      app = {
        hostnames                   = [""]
        origin_url                  = "https://origin.example.net"
        acme_challenge_cache_bypass = false
      }
    }
  }

  assert {
    condition     = length(output.pullzone_edge_rules) == 0
    error_message = "acme_challenge_cache_bypass = false must inject no edge rules"
  }
}

run "acme_bypass_not_duplicated_when_caller_has_acme_rule" {
  command = plan

  variables {
    domain = "example.com"
    pullzone_records = {
      app = {
        hostnames  = [""]
        origin_url = "https://origin.example.net"
        edge_rules = [
          {
            description = "Bypass cache for ACME HTTP-01 challenges"
            priority    = 400
            actions     = [{ type = "OverrideCacheTime", parameter1 = "0" }]
            triggers    = [{ type = "Url", patterns = ["*/.well-known/acme-challenge/*"] }]
          }
        ]
      }
    }
  }

  assert {
    condition     = length(output.pullzone_edge_rules) == 1
    error_message = "a caller rule matching acme-challenge must suppress the module default (no duplicate)"
  }
}

run "acme_bypass_only_on_enabled_zone" {
  command = plan

  variables {
    domain = "example.com"
    pullzone_records = {
      app = {
        hostnames  = [""]
        origin_url = "https://origin.example.net"
      }
      cdn = {
        hostnames                   = ["cdn"]
        origin_url                  = "https://origin.example.net"
        acme_challenge_cache_bypass = false
      }
    }
  }

  assert {
    condition = (
      contains(keys(output.pullzone_edge_rules), "app/acme/0") &&
      !contains(keys(output.pullzone_edge_rules), "cdn/acme/0")
    )
    error_message = "the bypass rule should be per-zone: injected for app, skipped for cdn"
  }
}
