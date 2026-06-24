
############################
#### Scaleway variables ####

variable "scaleway_project_id" {
  description = "Scaleway project ID"
  type        = string
}

variable "scaleway_region" {
  description = "Scaleway region ID"
  type        = string
}

############################
##### Module variables #####

# variable "flux_resources_helm_controller_cpu" {
#   description = "CPU resources to set for helm-controller"
#   type        = string
#   default     = "1"
# }

# variable "flux_resources_helm_controller_memory" {
#   description = "Memory resources to set for helm-controller"
#   type        = string
#   default     = "2Gi"
# }

# variable "flux_resources_source_controller_cpu" {
#   description = "CPU resources to set for source-controller"
#   type        = string
#   default     = "1"
# }

# variable "flux_resources_source_controller_memory" {
#   description = "Memory resources to set for source-controller"
#   type        = string
#   default     = "2Gi"
# }

variable "flux_secret_manager_secret_id" {
  description = "ID of the secret in Secret Manager that has the SSH key for Flux (latest version is used)"
  type        = string
}

variable "git_repo" {
  description = "Git repo to use for this cluster's state"
  type        = string
  default     = "kubernetes-state"
}

variable "git_repo_organization" {
  description = "Organization on GitHub that contains the git repo"
  type        = string
  default     = "mastodon-site"
}

variable "git_repo_path" {
  description = "Path for the cluster within the git repo"
  type        = string
}

variable "git_repo_branch" {
  description = "Branch to use from the git repo"
  type        = string
  default     = "main"
}

variable "kubernetes_cluster_name" {
  description = "Name of the Kubernetes cluster to create"
  type        = string
}

variable "kubernetes_cluster_version" {
  description = "Version of the Kubernetes cluster to create"
  type        = string
  default     = "1.34"
}

variable "kubernetes_node_pools" {
  description = <<-EOT
    Node pool(s) for the cluster. root_volume_type defaults to sbs_5k (block storage) and root_volume_size_in_gb to 20,
    matching typical Scaleway Kapsule pool defaults when these are omitted. Override for local SSD (l_ssd), higher-performance block (sbs_15k), etc.
  EOT
  type = list(object({
    pool_id                = number
    node_type              = string
    zone                   = string
    autoscaling            = bool
    autohealing            = bool
    size                   = number
    min_size               = number
    max_size               = number
    root_volume_type       = optional(string, "sbs_5k")
    root_volume_size_in_gb = optional(number, 20)
  }))
  default = [{
    pool_id     = 1
    node_type   = "play2_micro"
    zone        = "fr-par-1"
    autoscaling = true
    autohealing = true
    size        = 1
    min_size    = 2
    max_size    = 10
  }]
}

variable "private_network_id" {
  description = "ID of the private network in which to place the Kubernetes cluster"
  type        = string
}

##############################
## Load Balancer variables ###

variable "create_lb" {
  description = "Whether to create the ingress load balancer"
  type        = bool
  default     = true
}

variable "lb_type" {
  description = "Type of the Scaleway Load Balancer (e.g. LB-S, LB-GP-M)"
  type        = string
  default     = "LB-S"
}
