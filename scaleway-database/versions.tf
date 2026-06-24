terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">= 3.4.3"
    }
    scaleway = {
      source  = "scaleway/scaleway"
      version = ">= 2.24"
    }
  }
  required_version = ">= 1.4"
}