run "duplicate_hostnames" {
  command = plan

  variables {
    domain = "example.com"
    pullzone_records = {
      app = {
        hostnames  = [""]
        origin_url = "https://origin.example.net"
      }
      other = {
        hostnames  = [""]
        origin_url = "https://other.example.net"
      }
    }
  }

  expect_failures = [var.pullzone_records]
}

run "cname_collision" {
  command = plan

  variables {
    domain        = "example.com"
    cname_records = [{ name = "app", value = "somewhere.else.net" }]
    pullzone_records = {
      app = {
        hostnames  = ["app"]
        origin_url = "https://origin.example.net"
      }
    }
  }

  expect_failures = [var.pullzone_records]
}

run "a_record_collision" {
  command = plan

  variables {
    domain    = "example.com"
    a_records = [{ name = "", value = "1.2.3.4" }]
    pullzone_records = {
      apex = {
        hostnames  = [""]
        origin_url = "https://origin.example.net"
      }
    }
  }

  expect_failures = [var.pullzone_records]
}

run "storage_and_url_origin_conflict" {
  command = plan

  variables {
    domain = "example.com"
    storage_zones = {
      site = {
        region = "DE"
      }
    }
    pullzone_records = {
      site = {
        hostnames    = [""]
        origin_url   = "https://origin.example.net"
        storage_zone = "site"
      }
    }
  }

  expect_failures = [var.pullzone_records]
}

run "storage_origin_missing_zone" {
  command = plan

  variables {
    domain = "example.com"
    pullzone_records = {
      app = {
        hostnames    = [""]
        storage_zone = "missing"
      }
    }
  }

  expect_failures = [var.pullzone_records]
}

run "storage_origin_rejects_host_header_override" {
  command = plan

  variables {
    domain = "example.com"
    storage_zones = {
      site = {
        region = "DE"
      }
    }
    pullzone_records = {
      site = {
        hostnames           = [""]
        storage_zone        = "site"
        forward_host_header = false
      }
    }
  }

  expect_failures = [var.pullzone_records]
}

run "edge_storage_requires_de" {
  command = plan

  variables {
    domain = "example.com"
    storage_zones = {
      site = {
        region    = "UK"
        zone_tier = "Edge"
      }
    }
  }

  expect_failures = [var.storage_zones]
}

run "http_origin_requires_flag" {
  command = plan

  variables {
    domain = "example.com"
    pullzone_records = {
      s3 = {
        hostnames  = [""]
        origin_url = "http://bucket.s3-website.example.net"
      }
    }
  }

  expect_failures = [var.pullzone_records]
}
