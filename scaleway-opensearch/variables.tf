############################
#### Scaleway variables ####

variable "scaleway_project_id" {
  description = "ID of the Scaleway project to create resources in"
  type        = string
}

variable "scaleway_region" {
  description = "Scaleway region to deploy the OpenSearch cluster in"
  type        = string
}

############################
##### Module variables #####

variable "opensearch_cluster_name" {
  description = "Name of the OpenSearch cluster to create"
  type        = string
}

variable "enable_private_endpoint" {
  description = "When true (default), expose the cluster on a private network endpoint."
  type        = bool
  default     = true
}

variable "enable_public_endpoint" {
  description = "When true, expose the cluster on a public endpoint. Cannot be enabled together with enable_private_endpoint."
  type        = bool
  default     = false

  validation {
    condition     = var.enable_private_endpoint || var.enable_public_endpoint
    error_message = "At least one of enable_private_endpoint or enable_public_endpoint must be true."
  }

  validation {
    condition     = var.enable_private_endpoint != var.enable_public_endpoint
    error_message = "enable_private_endpoint and enable_public_endpoint cannot both be true: the Scaleway provider creates either a private or public endpoint, not both."
  }
}

variable "private_network_id" {
  description = "Private network ID for internal OpenSearch API access. Required when enable_private_endpoint is true."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = !var.enable_private_endpoint || var.private_network_id != null
    error_message = "private_network_id must be set when enable_private_endpoint is true."
  }
}

variable "opensearch_version" {
  description = "Version of OpenSearch to deploy"
  type        = string
  default     = "2.0"
}

variable "opensearch_node_type" {
  description = "Node type for the OpenSearch cluster"
  type        = string
  default     = "SEARCHDB-SHARED-2C-8G"
}

variable "opensearch_node_amount" {
  description = "Number of nodes in the OpenSearch cluster"
  type        = number
  default     = 1
}

variable "opensearch_volume_type" {
  description = "Volume type for the OpenSearch cluster storage"
  type        = string
  default     = "sbs_5k"
}

variable "opensearch_volume_size_in_gb" {
  description = "Volume size in GB for the OpenSearch cluster storage"
  type        = number
  default     = 10
}

variable "opensearch_user_name" {
  description = "Username to set for the primary cluster user"
  type        = string
  default     = "opensearch-user"
}
