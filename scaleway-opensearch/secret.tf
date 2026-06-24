resource "scaleway_secret" "main" {
  name = "opensearch--${var.opensearch_cluster_name}"
}

resource "scaleway_secret_version" "latest" {
  secret_id = scaleway_secret.main.id
  data      = random_password.cluster_password.result
}