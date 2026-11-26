output "database_id" {
  value = scaleway_rdb_instance.main.id
}

output "database_load_balancer" {
  value = scaleway_rdb_instance.main.load_balancer
}

output "database_name" {
  value = var.database_name
}

output "database_private_network_ip" {
  description = "Private network IP of the database instance (null when no private network endpoint is attached)"
  value       = try(scaleway_rdb_instance.main.private_network[0].ip, null)
}

output "database_private_network_port" {
  description = "PostgreSQL port on the private network endpoint (null when no private network endpoint is attached)"
  value       = try(scaleway_rdb_instance.main.private_network[0].port, null)
}

output "database_public_network_ip" {
  description = "Public load balancer IP when enable_public_network is true"
  value       = var.enable_public_network ? try(scaleway_rdb_instance.main.load_balancer[0].ip, null) : null
}

output "database_public_network_port" {
  description = "Public load balancer port when enable_public_network is true"
  value       = var.enable_public_network ? try(scaleway_rdb_instance.main.load_balancer[0].port, null) : null
}

output "database_user_name" {
  value = "uuid-${random_uuid.db_username.result}"
}
