output "database_instance_id" {
  description = "Scaleway RDB instance ID"
  value       = var.database_instance_id
}

output "database_name" {
  description = "Name of the logical database"
  value       = var.database_name
}

output "database_user_name" {
  description = "Database username"
  value       = local.database_user_name
}

output "database_password" {
  description = "Database password"
  value       = local.database_user_password
  sensitive   = true
}

output "database_secret_id" {
  description = "Scaleway Secret Manager secret ID when store_password_in_secret_manager is true"
  value       = var.store_password_in_secret_manager && var.create_user ? scaleway_secret.main[0].id : null
}

output "database_url" {
  description = "PostgreSQL connection URL when database_hostname is set"
  value       = local.database_url
  sensitive   = true
}
