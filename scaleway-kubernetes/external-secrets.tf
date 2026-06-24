resource "scaleway_iam_application" "external_secrets" {
  name = "external-secrets on ${var.kubernetes_cluster_name} Kubernetes cluster"
}

resource "scaleway_iam_api_key" "external_secrets" {
  application_id = scaleway_iam_application.external_secrets.id
  description    = "API key for external-secrets on ${var.kubernetes_cluster_name} Kubernetes cluster"
}

resource "scaleway_iam_policy" "external_secrets" {
  name           = "External-secrets (${var.kubernetes_cluster_name})"
  description    = "Grant external-secrets on the ${var.kubernetes_cluster_name} Kubernetes cluster access to Secret Manager"
  application_id = scaleway_iam_application.external_secrets.id
  rule {
    project_ids          = [var.scaleway_project_id]
    permission_set_names = ["SecretManagerFullAccess"]
  }
}

resource "kubernetes_secret" "scaleway_secret_manager_credentials" {
  metadata {
    name      = "scaleway-secret-manager-credentials"
    namespace = "kube-system"
  }

  data = {
    access-key        = scaleway_iam_api_key.external_secrets.access_key
    secret-access-key = scaleway_iam_api_key.external_secrets.secret_key
  }
}

# ClusterSecretStore is managed by Flux in kubernetes-state/kubernetes-0/platform/external-secrets.yaml
