locals {
  private_network_id_regional = scaleway_vpc_private_network.primary_subnet.id
}

output "private_network_id" {
  description = "Regional private network ID (region/uuid)."
  value       = local.private_network_id_regional
}

output "private_network_id_without_region" {
  description = "Private network ID without the regional prefix (uuid only)."
  value       = replace(local.private_network_id_regional, "${var.scaleway_region}/", "")
}

output "primary_subnet" {
  value = scaleway_vpc_private_network.primary_subnet.ipv4_subnet[0]
}

output "vpc_id" {
  value = scaleway_vpc.vpc.id
}

output "vpc_name" {
  value = var.vpc_name
}