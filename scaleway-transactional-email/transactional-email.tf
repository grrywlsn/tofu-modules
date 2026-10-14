resource "scaleway_tem_domain" "main" {
  name       = var.email_domain_name
  accept_tos = true
}

resource "scaleway_tem_webhook" "this" {
  for_each = { for idx, hook in var.webhooks : coalesce(hook.name, "webhook-${idx}") => hook }

  domain_id   = scaleway_tem_domain.main.id
  name        = each.key
  event_types = each.value.event_types
  sns_arn     = each.value.sns_arn
}