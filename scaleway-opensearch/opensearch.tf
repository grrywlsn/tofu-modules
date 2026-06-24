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

  volume {
    type       = var.opensearch_volume_type
    size_in_gb = var.opensearch_volume_size_in_gb
  }
}

locals {
  deployment_endpoints = tolist(try(scaleway_opensearch_deployment.deployment.endpoints, []))

  opensearch_private_api_urls = distinct(coalescelist(
    flatten([
      for endpoint in local.deployment_endpoints : [
        for service in try(endpoint.services, []) : service.url
        if try(service.name, "") == "api" && endswith(try(service.url, ""), ".internal")
      ]
    ]),
    flatten([
      for endpoint in local.deployment_endpoints : [
        for service in try(endpoint.services, []) : service.url
        if try(endpoint.private_network_id, "") != "" && try(service.name, "") == "api"
      ]
    ]),
    flatten([
      for endpoint in local.deployment_endpoints : [
        for service in try(endpoint.services, []) : service.url
        if try(endpoint.public, true) == false && try(service.name, "") == "api"
      ]
    ]),
    try(
      regexall("([0-9a-f-]+(?:-[0-9a-f-]+)+\\.[0-9a-f-]+(?:-[0-9a-f-]+)+\\.internal)", jsonencode(local.deployment_endpoints)),
      []
    )
  ))

  opensearch_internal_address = length(local.opensearch_private_api_urls) > 0 ? (
    startswith(local.opensearch_private_api_urls[0], "https://")
    ? local.opensearch_private_api_urls[0]
    : "https://${local.opensearch_private_api_urls[0]}"
  ) : null
}

check "opensearch_private_api_endpoint" {
  assert {
    condition     = length(local.opensearch_private_api_urls) > 0
    error_message = "No private OpenSearch API endpoint found in deployment endpoints: ${jsonencode(local.deployment_endpoints)}"
  }
}
