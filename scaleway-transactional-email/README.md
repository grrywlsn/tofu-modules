# scaleway-transactional-email

Terraform module to send transactional email via Scaleway.

## Optional webhooks

`webhooks` is empty by default and then creates nothing. Each entry activates Messaging and Queuing SNS in the provider project (if this module is the one activating it), creates a topic named `<domain-with-dots-as-hyphens>-<name>`, and attaches a TEM webhook that publishes the listed events to that topic.

```hcl
webhooks = [
  {
    name = "bounces"
    event_types = [
      "email_dropped",
      "email_mailbox_not_found",
    ]
  }
]
```

Topic ARNs are in the `sns_topic_arns` output. Subscribe each topic to the HTTPS endpoint that should receive the events. nvite.me verifies the SNS signature on `POST /v1/webhooks/email/bounce` and confirms `SubscriptionConfirmation` requests whose URL is on `scaleway.com`.

SNS is one activation per project and region. A second stack that also creates `scaleway_mnq_sns` for the same project should import the existing activation instead of creating another.
