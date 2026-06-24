output "opensearch_username" {
  description = "Username for the OpenSearch cluster"
  value       = var.opensearch_user_name
}

output "opensearch_password" {
  description = "Generated password for the OpenSearch cluster"
  value       = random_password.cluster_password.result
  sensitive   = true
}

output "opensearch_cluster_name" {
  description = "Name of the OpenSearch cluster"
  value       = var.opensearch_cluster_name
}

output "opensearch_internal_address" {
  description = "Internal HTTPS URL for the OpenSearch API"
  value       = local.opensearch_internal_address
}

output "opensearch_public_dashboard_url" {
  description = "Public URL for OpenSearch Dashboards when exposed on a public endpoint"
  value       = scaleway_opensearch_deployment.deployment.public_dashboard_url
}
