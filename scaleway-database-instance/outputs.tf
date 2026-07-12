output "database_id" {
  value = scaleway_rdb_instance.main.id
}

output "database_load_balancer" {
  value = scaleway_rdb_instance.main.load_balancer
}

output "database_name" {
  value = var.database_name
}

output "database_private_network" {
  value = scaleway_rdb_instance.main.private_network[0].ip
}

output "database_user_name" {
  value = "uuid-${random_uuid.db_username.result}"
}