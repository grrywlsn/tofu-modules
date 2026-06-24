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
}

variable "private_network_id" {
  description = "Private network ID for internal OpenSearch API access. Required when enable_private_endpoint is true."
  type        = string
  default     = null
  nullable    = true
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
