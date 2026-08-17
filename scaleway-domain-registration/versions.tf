terraform {
  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "2.81.0"
    }
    shell = {
      source  = "scottwinkler/shell"
      version = "1.7.10"
    }
  }
  required_version = ">= 1.4"
}
