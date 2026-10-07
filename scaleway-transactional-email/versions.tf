terraform {
  required_providers {

    scaleway = {
      source  = "scaleway/scaleway"
      version = "2.86.0"
    }
  }
  required_version = ">= 1.3"
}