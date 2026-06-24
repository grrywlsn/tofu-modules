resource "scaleway_vpc" "vpc" {
  name   = var.vpc_name
  region = var.scaleway_region
}

resource "scaleway_vpc_private_network" "primary_subnet" {
  name   = var.vpc_name
  region = var.scaleway_region
  vpc_id = scaleway_vpc.vpc.id
}