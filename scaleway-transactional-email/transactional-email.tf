locals {
  webhooks = {
    for idx, hook in var.webhooks : coalesce(hook.name, "webhook-${idx}") => hook
  }
  # Topic names are unique per domain so two domains in one project can both
  # use a webhook named "bounces". SNS allows only [A-Za-z0-9_-]{1,80}.
  sns_topic_names = {
    for name, _ in local.webhooks :
    name => substr("${replace(var.email_domain_name, ".", "-")}-${name}", 0, 80)
  }
}

resource "scaleway_tem_domain" "main" {
  name       = var.email_domain_name
  accept_tos = true
}

resource "scaleway_mnq_sns" "webhooks" {
  count = length(var.webhooks) > 0 ? 1 : 0
}

resource "scaleway_mnq_sns_credentials" "webhooks" {
  count = length(var.webhooks) > 0 ? 1 : 0

  project_id = scaleway_mnq_sns.webhooks[0].project_id
  name       = substr("${replace(var.email_domain_name, ".", "-")}-tem", 0, 80)

  permissions {
    can_manage = true
  }
}

resource "scaleway_mnq_sns_topic" "webhooks" {
  for_each = local.webhooks

  project_id = scaleway_mnq_sns.webhooks[0].project_id
  name       = local.sns_topic_names[each.key]
  access_key = scaleway_mnq_sns_credentials.webhooks[0].access_key
  secret_key = scaleway_mnq_sns_credentials.webhooks[0].secret_key
}

resource "scaleway_tem_webhook" "this" {
  for_each = local.webhooks

  domain_id   = scaleway_tem_domain.main.id
  name        = each.key
  event_types = each.value.event_types
  sns_arn     = scaleway_mnq_sns_topic.webhooks[each.key].arn
}