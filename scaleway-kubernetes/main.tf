provider "kubernetes" {
  host  = scaleway_k8s_cluster.cluster.kubeconfig[0].host
  token = scaleway_k8s_cluster.cluster.kubeconfig[0].token
  cluster_ca_certificate = base64decode(
    scaleway_k8s_cluster.cluster.kubeconfig[0].cluster_ca_certificate,
  )
}

provider "helm" {
  kubernetes = {
    host  = scaleway_k8s_cluster.cluster.kubeconfig[0].host
    token = scaleway_k8s_cluster.cluster.kubeconfig[0].token
    cluster_ca_certificate = base64decode(
      scaleway_k8s_cluster.cluster.kubeconfig[0].cluster_ca_certificate,
    )
  }
}

data "scaleway_secret_version" "flux_ssh_key" {
  secret_id = var.flux_secret_manager_secret_id
  revision  = "latest"
}
