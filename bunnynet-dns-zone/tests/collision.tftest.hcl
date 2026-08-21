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
