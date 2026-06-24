variable "database_allowed_ips" {
  description = "List of IP CIDRs that are allowed to connect to the instance"
  type        = list(string)
  default     = []
}

variable "database_engine" {
  description = "Database engine type"
  type        = string
  default     = "PostgreSQL-15"
}

variable "database_highly_available" {
  description = "If the database instance is highly available (boolean)"
  type        = bool
  default     = true
}

variable "database_storage_size_gb" {
  description = "Local storage to provision for the database (GB)"
  type        = string
  default     = "10"
}

# Optional Scaleway RDB engine settings (PostgreSQL parameter names to values). Empty {} keeps engine defaults.
# Values are strings as required by the API (e.g. max_connections = "100"; timeouts often as milliseconds like "600000").
variable "database_settings" {
  description = "Map of Scaleway RDB setting names to values."
  type        = map(string)
  default     = {}
}

variable "database_name" {
  description = "Name of the database instance to create"
  type        = string
}

variable "database_node_type" {
  description = "Type of node to use for the database instance"
  type        = string
  default     = "DB-PLAY2-PICO"
}

variable "private_network_id" {
  description = "ID of the private network in which to place the database"
  type        = string
}

variable "volume_type" {
  description = "Volume type to use for the database instance"
  type        = string
  default     = "sbs_15k"
}