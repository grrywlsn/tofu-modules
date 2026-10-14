# scaleway-transactional-email

Terraform module to send transactional email via Scaleway.

## Optional webhooks

`webhooks` attaches Scaleway Transactional Email events to an SNS topic the caller already owns. An empty list creates no webhooks.

```hcl
webhooks = [
  {
    name = "bounces"
    event_types = [
      "email_dropped",
      "email_mailbox_not_found",
    ]
    sns_arn = scaleway_mnq_sns_topic.bounces.arn
  }
]
```

Subscribe that topic to the HTTPS endpoint that should receive the events. nvite.me verifies the SNS signature on `POST /v1/webhooks/email/bounce` and confirms `SubscriptionConfirmation` requests whose URL is on `scaleway.com`.
