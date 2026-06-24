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
  opensearch_api_urls = flatten([
    for endpoint in scaleway_opensearch_deployment.deployment.endpoints : [
      for service in endpoint.services : service.url
      if contains(["api", "opensearch"], service.name)
    ]
  ])

  opensearch_formatted_api_urls = [
    for url in local.opensearch_api_urls :
    startswith(url, "http") ? url : "https://${url}"
  ]

  opensearch_internal_address   = var.enable_private_endpoint ? try(local.opensearch_formatted_api_urls[0], null) : null
  opensearch_public_api_address = var.enable_public_endpoint ? try(local.opensearch_formatted_api_urls[0], null) : null
}