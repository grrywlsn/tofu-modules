locals {
  webhooks_enabled = length(var.webhook_event_types) > 0
  # SNS topic names allow only [A-Za-z0-9_-]{1,80}.
  sns_topic_name = substr(replace(var.email_domain_name, ".", "-"), 0, 80)
}

resource "scaleway_tem_domain" "main" {
  name       = var.email_domain_name
  accept_tos = true
}

resource "scaleway_mnq_sns" "webhook" {
  count = local.webhooks_enabled ? 1 : 0
}

resource "scaleway_mnq_sns_credentials" "webhook" {
  count = local.webhooks_enabled ? 1 : 0

  project_id = scaleway_mnq_sns.webhook[0].project_id
  name       = local.sns_topic_name

  permissions {
    can_manage  = true
    can_receive = true
  }
}

resource "scaleway_mnq_sns_topic" "webhook" {
  count = local.webhooks_enabled ? 1 : 0

  project_id = scaleway_mnq_sns.webhook[0].project_id
  name       = local.sns_topic_name
  access_key = scaleway_mnq_sns_credentials.webhook[0].access_key
  secret_key = scaleway_mnq_sns_credentials.webhook[0].secret_key
}

resource "scaleway_tem_webhook" "webhook" {
  count = local.webhooks_enabled ? 1 : 0

  domain_id   = scaleway_tem_domain.main.id
  name        = local.sns_topic_name
  event_types = var.webhook_event_types
  sns_arn     = scaleway_mnq_sns_topic.webhook[0].arn
}

resource "scaleway_mnq_sqs" "webhook" {
  count = local.webhooks_enabled ? 1 : 0
}

resource "scaleway_mnq_sqs_credentials" "manage" {
  count = local.webhooks_enabled ? 1 : 0

  project_id = scaleway_mnq_sqs.webhook[0].project_id
  name       = substr("${local.sns_topic_name}-manage", 0, 80)

  permissions {
    can_manage = true
  }
}

resource "scaleway_mnq_sqs_credentials" "receive" {
  count = local.webhooks_enabled ? 1 : 0

  project_id = scaleway_mnq_sqs.webhook[0].project_id
  name       = substr("${local.sns_topic_name}-receive", 0, 80)

  permissions {
    can_receive = true
  }
}

resource "scaleway_mnq_sqs_queue" "dead_letter" {
  count = local.webhooks_enabled ? 1 : 0

  project_id   = scaleway_mnq_sqs.webhook[0].project_id
  name         = substr("${local.sns_topic_name}-dlq", 0, 80)
  sqs_endpoint = scaleway_mnq_sqs.webhook[0].endpoint
  access_key   = scaleway_mnq_sqs_credentials.manage[0].access_key
  secret_key   = scaleway_mnq_sqs_credentials.manage[0].secret_key
}

resource "scaleway_mnq_sqs_queue" "webhook" {
  count = local.webhooks_enabled ? 1 : 0

  project_id                 = scaleway_mnq_sqs.webhook[0].project_id
  name                       = local.sns_topic_name
  sqs_endpoint               = scaleway_mnq_sqs.webhook[0].endpoint
  access_key                 = scaleway_mnq_sqs_credentials.manage[0].access_key
  secret_key                 = scaleway_mnq_sqs_credentials.manage[0].secret_key
  visibility_timeout_seconds = 60

  # The API stores this as region/project/name. Setting the ARN makes every
  # plan rewrite it back to that id.
  dead_letter_queue {
    id                = scaleway_mnq_sqs_queue.dead_letter[0].id
    max_receive_count = 5
  }
}

resource "scaleway_mnq_sns_topic_subscription" "webhook" {
  count = local.webhooks_enabled ? 1 : 0

  project_id = scaleway_mnq_sns.webhook[0].project_id
  topic_arn  = scaleway_mnq_sns_topic.webhook[0].arn
  protocol   = "sqs"
  endpoint   = scaleway_mnq_sqs_queue.webhook[0].arn
  access_key = scaleway_mnq_sns_credentials.webhook[0].access_key
  secret_key = scaleway_mnq_sns_credentials.webhook[0].secret_key
}

resource "scaleway_secret" "webhook" {
  count = local.webhooks_enabled ? 1 : 0

  name = "tem--${local.sns_topic_name}"
}

resource "scaleway_secret_version" "webhook" {
  count = local.webhooks_enabled ? 1 : 0

  secret_id = scaleway_secret.webhook[0].id
  data = jsonencode({
    topic_arn      = scaleway_mnq_sns_topic.webhook[0].arn
    queue_url      = scaleway_mnq_sqs_queue.webhook[0].url
    sqs_access_key = scaleway_mnq_sqs_credentials.receive[0].access_key
    sqs_secret_key = scaleway_mnq_sqs_credentials.receive[0].secret_key
  })
}
