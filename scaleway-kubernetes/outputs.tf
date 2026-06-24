output "lb_ipv4_address" {
  description = "Public IPv4 address of the ingress load balancer"
  value       = var.create_lb ? scaleway_lb_ip.ingress_ipv4[0].ip_address : null
}

output "lb_ipv6_address" {
  description = "Public IPv6 address of the ingress load balancer"
  value       = var.create_lb ? scaleway_lb_ip.ingress_ipv6[0].ip_address : null
}

output "lb_id" {
  description = "ID of the ingress load balancer"
  value       = var.create_lb ? scaleway_lb.ingress[0].id : null
}
