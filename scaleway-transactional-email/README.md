# scaleway-transactional-email

Terraform module to send transactional email via Scaleway.

## Optional webhook

`webhook_event_types` is empty by default and then creates nothing. One or more event types activate Messaging and Queuing SNS in the provider project, create one topic named after the domain (`mail.nvite.me` becomes `mail-nvite-me`), and attach one TEM webhook that publishes every listed event to that topic.

```hcl
webhook_event_types = [
  "email_dropped",
  "email_mailbox_not_found",
]
```

The topic ARN is `sns_topic_arn`. The same apply writes a Secrets Manager secret named `tem--<topic>` (`sns_credentials_secret_id`) whose version is JSON:

```json
{ "access_key": "...", "secret_key": "...", "topic_arn": "..." }
```

Those fields are what `scaleway_mnq_sns_topic_subscription` needs. Subscribe that topic to the HTTPS endpoint that should receive the events. nvite.me verifies the SNS signature on `POST /v1/webhooks/email/bounce` and confirms `SubscriptionConfirmation` requests whose URL is on `scaleway.com`.

SNS is one activation per project and region. A second stack that also creates `scaleway_mnq_sns` for the same project should import the existing activation instead of creating another.
