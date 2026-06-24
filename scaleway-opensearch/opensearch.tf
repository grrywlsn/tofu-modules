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
