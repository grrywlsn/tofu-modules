variable "bucket_name" {
  description = "Globally unique Object Storage bucket name"
  type        = string
}

variable "region" {
  description = "Scaleway region in which to create the bucket"
  type        = string
  default     = "fr-par"
}

variable "acl" {
  description = "Canned ACL to apply to the bucket; null leaves the provider default"
  type        = string
  default     = null
  nullable    = true
}

variable "website_enabled" {
  description = "Whether to configure the bucket as a static website"
  type        = bool
  default     = false
}

variable "website_index_document" {
  description = "Index document suffix used when website configuration is enabled"
  type        = string
  default     = "index.html"
}

variable "abort_incomplete_multipart_upload_days" {
  description = "Days after which incomplete multipart uploads are aborted; null disables the lifecycle rule"
  type        = number
  default     = null
  nullable    = true

  validation {
    condition     = var.abort_incomplete_multipart_upload_days == null || var.abort_incomplete_multipart_upload_days >= 1
    error_message = "abort_incomplete_multipart_upload_days must be null or at least 1."
  }
}
