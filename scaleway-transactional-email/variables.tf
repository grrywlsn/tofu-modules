variable "email_domain_name" {
  description = "Name of domain to set up for emails (eg: notifications.example.com)"
  type        = string
}

variable "webhooks" {
  description = <<-EOT
    Optional Transactional Email webhooks. Leave empty to create none.
    Each entry creates a Messaging and Queuing SNS topic in this project and
    attaches a TEM webhook that publishes the listed events to it. The caller
    still subscribes that topic to an HTTPS endpoint.
  EOT
  type = list(object({
    name        = optional(string)
    event_types = list(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for idx, hook in var.webhooks :
      can(regex("^[A-Za-z0-9_-]{1,80}$", coalesce(hook.name, "webhook-${idx}"))) && length(hook.event_types) > 0 && alltrue([
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
    error_message = "webhooks names must match ^[A-Za-z0-9_-]{1,80}$ and event_types must be drawn from email_queued, email_dropped, email_deferred, email_delivered, email_spam, email_mailbox_not_found, and email_blocklisted."
  }

  validation {
    condition = length(var.webhooks) == length(distinct([
      for idx, hook in var.webhooks : coalesce(hook.name, "webhook-${idx}")
    ]))
    error_message = "webhooks names must be unique. An omitted name becomes webhook-<index>."
  }

  validation {
    condition = alltrue([
      for idx, hook in var.webhooks :
      length("${replace(var.email_domain_name, ".", "-")}-${coalesce(hook.name, "webhook-${idx}")}") <= 80
    ])
    error_message = "SNS topic names are <domain-with-dots-as-hyphens>-<webhook name> and must be at most 80 characters."
  }
}