resource "random_password" "cluster_password" {
  length           = 30
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 1
  override_special = "!"
}

resource "scaleway_opensearch_deployment" "deployment" {
  name       = var.opensearch_cluster_name
  region     = var.scaleway_region
  project_id = var.scaleway_project_id
  version    = var.opensearch_version
  node_count = var.opensearch_node_count
  node_type  = var.opensearch_node_type
  user_name  = var.opensearch_user_name
  password   = random_password.cluster_password.result

  dynamic "private_network" {
    for_each = var.enable_private_endpoint ? [var.private_network_id] : []
    content {
      private_network_id = private_network.value
    }
  }

  volume {
    type       = var.opensearch_volume_type
    size_in_gb = var.opensearch_volume_size_in_gb
  }
}

locals {
  # Scaleway has renamed endpoint services over time (e.g. api -> api-opensearch).
  # Match known names and fall back to ports so downstream outputs stay stable.
  opensearch_api_service_names       = ["api", "api-opensearch", "opensearch"]
  opensearch_dashboard_service_names = ["dashboard", "dashboards", "dashboard-opensearch", "dashboards-opensearch"]

  opensearch_api_urls = flatten([
    for endpoint in scaleway_opensearch_deployment.deployment.endpoints : [
      for service in endpoint.services : service.url
      if contains(local.opensearch_api_service_names, service.name) || service.port == 9200
    ]
  ])

  # Keep the same shape as the provider's public_dashboard_url (raw host, no scheme).
  opensearch_dashboard_urls = flatten([
    for endpoint in scaleway_opensearch_deployment.deployment.endpoints : [
      for service in endpoint.services : service.url
      if endpoint.public && (
        contains(local.opensearch_dashboard_service_names, service.name) || service.port == 5601
      )
    ]
  ])

  opensearch_formatted_api_urls = [
    for url in local.opensearch_api_urls :
    startswith(url, "http") ? url : "https://${url}"
  ]

  opensearch_internal_address   = var.enable_private_endpoint ? try(local.opensearch_formatted_api_urls[0], null) : null
  opensearch_public_api_address = var.enable_public_endpoint ? try(local.opensearch_formatted_api_urls[0], null) : null

  # Prefer the provider attribute when set; otherwise derive from endpoints.
  # Empty string is treated as unset (provider returns "" when no match).
  opensearch_public_dashboard_url = (
    try(scaleway_opensearch_deployment.deployment.public_dashboard_url, null) != null &&
    try(scaleway_opensearch_deployment.deployment.public_dashboard_url, "") != ""
    ? scaleway_opensearch_deployment.deployment.public_dashboard_url
    : try(local.opensearch_dashboard_urls[0], null)
  )
}
