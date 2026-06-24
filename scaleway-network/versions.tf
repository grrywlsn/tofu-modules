terraform {
  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = ">= 2.24"
    }
  }
  required_version = ">= 1.4"
}