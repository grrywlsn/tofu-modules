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
