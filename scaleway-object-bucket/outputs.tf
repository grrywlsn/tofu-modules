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
