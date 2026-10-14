variable "email_domain_name" {
  description = "Name of domain to set up for emails (eg: notifications.example.com)"
  type        = string
}

variable "webhook_event_types" {
  description = <<-EOT
    Transactional Email event types to publish for this domain. Empty creates
    no SNS topic and no webhook. One or more values create a single topic and
    a single webhook that publishes every listed event to it.
  EOT
  type        = list(string)
  default     = []

  validation {
    condition = length(var.webhook_event_types) == length(distinct(var.webhook_event_types)) && alltrue([
      for event_type in var.webhook_event_types :
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
    error_message = "webhook_event_types must be unique and drawn from email_queued, email_dropped, email_deferred, email_delivered, email_spam, email_mailbox_not_found, and email_blocklisted."
  }
}
