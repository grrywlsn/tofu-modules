terraform {
  required_providers {

    scaleway = {
      source  = "scaleway/scaleway"
      version = ">= 2.35"
    }
  }
  required_version = ">= 1.3"
}