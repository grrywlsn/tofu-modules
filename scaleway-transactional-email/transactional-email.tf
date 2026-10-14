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
    can_manage = true
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
