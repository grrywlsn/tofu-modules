output "opensearch_username" {
  description = "Default username for the OpenSearch cluster"
  value       = "opensearch-user"
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
  value = (
    startswith(local.opensearch_private_api_hostname, "https://")
    ? local.opensearch_private_api_hostname
    : "https://${local.opensearch_private_api_hostname}"
  )
}
