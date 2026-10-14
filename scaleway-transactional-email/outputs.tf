output "email_domain_name" {
  value = var.email_domain_name
}

output "email_smtp_host" {
  value = scaleway_tem_domain.main.smtp_host
}

output "email_smtp_port" {
  value = scaleway_tem_domain.main.smtp_port
}

# Scaleway blocks outbound 25, 465 and 587 from Instances and Kubernetes nodes, so
# workloads sending from inside Scaleway need the alternative TLS port instead.
output "email_smtp_port_alternative" {
  value = scaleway_tem_domain.main.smtp_port_alternative
}

output "webhook_id" {
  description = "Scaleway TEM webhook ID. Null when webhook_event_types is empty."
  value       = one(scaleway_tem_webhook.webhook[*].id)
}

output "sns_topic_arn" {
  description = "ARN of the single SNS topic for this domain's webhook. Null when webhook_event_types is empty."
  value       = one(scaleway_mnq_sns_topic.webhook[*].arn)
}

output "sns_credentials_secret_id" {
  description = "Secrets Manager secret ID for the SNS access_key, secret_key, and topic_arn. Null when webhook_event_types is empty."
  value       = one(scaleway_secret.webhook[*].id)
}
