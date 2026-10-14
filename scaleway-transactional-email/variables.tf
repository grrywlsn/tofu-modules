variable "email_domain_name" {
  description = "Name of domain to set up for emails (eg: notifications.example.com)"
  type        = string
}

variable "webhooks" {
  description = <<-EOT
    Optional Transactional Email webhooks. Each entry publishes the listed
    events for this domain to an existing Scaleway Topics and Events (SNS)
    topic. Leave empty to create no webhooks. The topic and its HTTPS
    subscription are owned by the caller; this module only attaches the TEM
    webhook to the topic ARN.
  EOT
  type = list(object({
    name        = optional(string)
    event_types = list(string)
    sns_arn     = string
  }))
  default = []

  validation {
    condition = alltrue([
      for hook in var.webhooks :
      length(trimspace(hook.sns_arn)) > 0 && length(hook.event_types) > 0 && alltrue([
        for event_type in hook.event_types :
        contains([
          "email_queued",
          "email_dropped",
          "email_deferred",
          "email_delivered",
          "email_spam",
          "email_mailbox_not_found",
          "email_blocklisted",
        ], event_type)
      ])
    ])
    error_message = "webhooks entries require a non-empty sns_arn and event_types drawn from email_queued, email_dropped, email_deferred, email_delivered, email_spam, email_mailbox_not_found, and email_blocklisted."
  }
}