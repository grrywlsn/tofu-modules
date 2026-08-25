output "bucket_id" {
  description = "Object Storage bucket ID"
  value       = scaleway_object_bucket.main.id
}

output "bucket_name" {
  description = "Object Storage bucket name"
  value       = scaleway_object_bucket.main.name
}

output "website_endpoint" {
  description = "Static website endpoint when website configuration is enabled"
  value       = var.website_enabled ? scaleway_object_bucket_website_configuration.main[0].website_endpoint : null
}

output "server_side_encryption_id" {
  description = "Regional ID of the bucket server-side encryption configuration"
  value       = scaleway_object_bucket_server_side_encryption_configuration.main.id
}
