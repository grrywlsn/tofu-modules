output "email_domain_name" {
  value = var.email_domain_name
}

output "email_smtp_host" {
  value = scaleway_tem_domain.main.smtp_host
}

output "email_smtp_port" {
  value = scaleway_tem_domain.main.smtp_port
}
