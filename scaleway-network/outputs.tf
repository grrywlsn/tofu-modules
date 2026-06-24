output "private_network_id" {
  value = scaleway_vpc_private_network.primary_subnet.id
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