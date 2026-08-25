variable "application_name" {
  description = "IAM application name"
  type        = string
}

variable "api_key_description" {
  description = "Description attached to the IAM API key; null uses the application name"
  type        = string
  default     = null
  nullable    = true
}

variable "project_id" {
  description = "Scaleway project used by the API key and IAM policy"
  type        = string
}

variable "policy_name" {
  description = "IAM policy name"
  type        = string
}

variable "policy_description" {
  description = "IAM policy description"
  type        = string
  default     = null
  nullable    = true
}

variable "permission_set_names" {
  description = "Scaleway permission sets granted to the application in the project"
  type        = list(string)

  validation {
    condition     = length(var.permission_set_names) > 0
    error_message = "permission_set_names must contain at least one permission set."
  }
}
