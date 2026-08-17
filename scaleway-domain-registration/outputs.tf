output "id" {
  description = "ID of the domain registration (project_id/task_id)."
  value       = scaleway_domain_registration.this.id
}

output "domain" {
  description = "Managed domain name."
  value       = var.domain
}

output "task_id" {
  description = "Task ID of the domain registration."
  value       = scaleway_domain_registration.this.task_id
}

output "project_id" {
  description = "Scaleway project ID of the registration."
  value       = scaleway_domain_registration.this.project_id
}

output "auto_renew" {
  description = "Whether auto-renewal is enabled on the registration resource."
  value       = scaleway_domain_registration.this.auto_renew
}

output "dnssec_enabled" {
  description = "Whether DNSSEC is requested via this module."
  value       = var.dnssec_enabled
}

output "owner_contact_id" {
  description = "Owner contact ID assigned by Scaleway."
  value       = scaleway_domain_registration.this.owner_contact_id
}

output "owner_contact" {
  description = "Owner contact details on the registration."
  value       = scaleway_domain_registration.this.owner_contact
}

output "administrative_contact" {
  description = "Administrative contact details returned by Scaleway."
  value       = scaleway_domain_registration.this.administrative_contact
}

output "technical_contact" {
  description = "Technical contact details returned by Scaleway."
  value       = scaleway_domain_registration.this.technical_contact
}

output "dnssec_ds_record" {
  description = "DS record reported by the Scaleway registration resource (may lag API enable)."
  value       = scaleway_domain_registration.this.ds_record
}
