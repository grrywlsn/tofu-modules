# scaleway-kubernetes

Terraform module to create and maintain a Kubernetes cluster on Scaleway

## Upgrading to v2.0.0+

v2.0.0 migrates `kubernetes_secret` resources to `kubernetes_secret_v1`. Before applying, run `state rm` + `import` for each secret — see the [v2.0.0 release notes](https://github.com/grrywlsn/tofu-modules/releases/tag/scaleway-kubernetes-v2.0.0).