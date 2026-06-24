resource "helm_release" "flux_operator" {
  name             = "flux-operator"
  namespace        = "flux-system"
  repository       = "oci://ghcr.io/controlplaneio-fluxcd/charts"
  chart            = "flux-operator"
  version          = "0.43.0"
  create_namespace = true
  depends_on       = [scaleway_k8s_pool.pools]
}

resource "kubernetes_secret" "flux_git_credentials" {
  depends_on = [helm_release.flux_operator]

  metadata {
    name      = "flux-system"
    namespace = "flux-system"
  }

  type = "Opaque"

  data = {
    identity    = base64decode(data.scaleway_secret_version.flux_ssh_key.data)
    known_hosts = "github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl"
  }
}

resource "helm_release" "flux_instance" {
  depends_on = [
    helm_release.flux_operator,
    kubernetes_secret.flux_git_credentials,
  ]

  name       = "flux"
  namespace  = "flux-system"
  repository = "oci://ghcr.io/controlplaneio-fluxcd/charts"
  chart      = "flux-instance"
  version    = "0.43.0"

  values = [
    file("values/components.yaml"),
    yamlencode({
      instance = {
        sync = {
          url  = "ssh://git@github.com/${var.git_repo_organization}/${var.git_repo}.git"
          ref  = "refs/heads/${var.git_repo_branch}"
          path = var.git_repo_path
        }
      }
    })
  ]
}
