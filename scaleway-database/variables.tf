variable "database_instance_id" {
  description = "Scaleway RDB instance ID on which to create database objects"
  type        = string
}

variable "database_name" {
  description = "Name of the logical database"
  type        = string
}

variable "create_database" {
  description = "Whether to create a scaleway_rdb_database"
  type        = bool
  default     = true
}

variable "create_user" {
  description = "Whether to create a scaleway_rdb_user"
  type        = bool
  default     = true
}

variable "create_privilege" {
  description = "Whether to create a scaleway_rdb_privilege"
  type        = bool
  default     = true
}

variable "database_user_name" {
  description = "Database username. When null and create_user is true, a random UUID is generated without a uuid- prefix"
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = !var.create_privilege || var.create_user || var.database_user_name != null
    error_message = "database_user_name must be set when create_privilege is true and create_user is false."
  }
}

variable "database_user_password" {
  description = "Database password. When null and create_user is true, a random password is generated"
  type        = string
  default     = null
  nullable    = true
  sensitive   = true

  validation {
    condition     = !var.create_user || var.database_user_password == null || var.database_user_name != null
    error_message = "database_user_name must be set when database_user_password is provided."
  }
}

variable "database_user_is_admin" {
  description = "Whether the database user is an admin"
  type        = bool
  default     = true
}

variable "database_privilege_permission" {
  description = "Permission level for the database privilege"
  type        = string
  default     = "all"
}

variable "store_password_in_secret_manager" {
  description = "Whether to store the database password in Scaleway Secret Manager"
  type        = bool
  default     = false
}
