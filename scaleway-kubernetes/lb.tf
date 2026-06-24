resource "scaleway_lb_ip" "ingress_ipv4" {
  count = var.create_lb ? 1 : 0
}

resource "scaleway_lb_ip" "ingress_ipv6" {
  count   = var.create_lb ? 1 : 0
  is_ipv6 = true
}

resource "scaleway_lb" "ingress" {
  count                   = var.create_lb ? 1 : 0
  ip_ids                  = [scaleway_lb_ip.ingress_ipv4[0].id, scaleway_lb_ip.ingress_ipv6[0].id]
  name                    = "${var.kubernetes_cluster_name}-ingress"
  ssl_compatibility_level = "ssl_compatibility_level_modern"
  type                    = var.lb_type

  private_network {
    private_network_id = var.private_network_id
  }
}
