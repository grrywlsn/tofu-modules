resource "scaleway_tem_domain" "main" {
  name       = var.email_domain_name
  accept_tos = true
}