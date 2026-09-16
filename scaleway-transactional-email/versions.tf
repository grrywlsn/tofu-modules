terraform {
  required_providers {

    scaleway = {
      source  = "scaleway/scaleway"
      version = "2.83.1"
    }
  }
  required_version = ">= 1.3"
}