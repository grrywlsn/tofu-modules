resource "random_password" "cluster_password" {
  length           = 30
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 1
  override_special = "!"
}

resource "scaleway_opensearch_deployment" "deployment" {
  name        = var.opensearch_cluster_name
  region      = var.scaleway_region
  project_id  = var.scaleway_project_id
  version     = var.opensearch_version
  node_amount = var.opensearch_node_amount
  node_type   = var.opensearch_node_type
  user_name   = var.opensearch_user_name
  password    = random_password.cluster_password.result

  private_network {
    private_network_id = var.private_network_id
  }

  volume {
    type       = var.opensearch_volume_type
    size_in_gb = var.opensearch_volume_size_in_gb
  }
}

locals {
  # With private_network configured, the provider filters deployment.endpoints to the
  # private endpoint only. Pick the API service URL from that endpoint.
  # https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/opensearch_deployment#attributes-reference
  opensearch_private_api_urls = flatten([
    for endpoint in scaleway_opensearch_deployment.deployment.endpoints : [
      for service in endpoint.services : service.url
      if contains(["api", "opensearch"], service.name)
    ]
  ])

  opensearch_internal_address = length(local.opensearch_private_api_urls) > 0 ? (
    startswith(local.opensearch_private_api_urls[0], "http")
    ? local.opensearch_private_api_urls[0]
    : "https://${local.opensearch_private_api_urls[0]}"
  ) : null
}

check "opensearch_private_api_endpoint" {
  assert {
    condition     = length(local.opensearch_private_api_urls) > 0
    error_message = "No private OpenSearch API endpoint found. Ensure private_network_id is set and matches the deployment: ${jsonencode(scaleway_opensearch_deployment.deployment.endpoints)}"
  }
}
