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

The topic ARN is `sns_topic_arn`. The same apply creates one queue, subscribes the topic to it, and writes a Secrets Manager secret named `tem--<topic>` (`sns_credentials_secret_id`) whose version is JSON:

```json
{
  "topic_arn": "...",
  "queue_url": "...",
  "sqs_access_key": "...",
  "sqs_secret_key": "..."
}
```

The queue hides a received message from other consumers for 60 seconds. A message that is received 5 times without being deleted moves to a dead-letter queue. Pods use the receive-only keys to pull. The SNS keys that create the topic stay in Terraform state.

SNS is one activation per project and region. A second stack that also creates `scaleway_mnq_sns` for the same project should import the existing activation instead of creating another.
