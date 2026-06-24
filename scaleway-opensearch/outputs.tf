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
  description = "Internal HTTPS URL for the OpenSearch API (private network endpoint only)"
  value       = local.opensearch_internal_address
}

output "opensearch_public_api_address" {
  description = "Public HTTPS URL for the OpenSearch API (only when enable_public_endpoint is true)"
  value       = local.opensearch_public_api_address
}

output "opensearch_public_dashboard_url" {
  description = "Public URL for OpenSearch Dashboards when a public endpoint exists"
  value       = scaleway_opensearch_deployment.deployment.public_dashboard_url
}
