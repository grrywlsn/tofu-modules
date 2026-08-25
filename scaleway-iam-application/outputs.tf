output "application_id" {
  description = "IAM application ID"
  value       = scaleway_iam_application.main.id
}

output "access_key" {
  description = "IAM API access key ID"
  value       = scaleway_iam_api_key.main.access_key
}

output "secret_key" {
  description = "IAM API secret key"
  value       = scaleway_iam_api_key.main.secret_key
  sensitive   = true
}

output "policy_id" {
  description = "IAM policy ID"
  value       = scaleway_iam_policy.main.id
}
