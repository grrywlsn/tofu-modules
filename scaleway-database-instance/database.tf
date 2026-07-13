resource "random_uuid" "db_username" {
}

resource "random_password" "db_password" {
  length           = 30
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 1
  override_special = "!"
}

resource "scaleway_rdb_instance" "main" {
  name                      = var.database_name
  node_type                 = var.database_node_type
  engine                    = var.database_engine
  is_ha_cluster             = var.database_highly_available
  user_name                 = "uuid-${random_uuid.db_username.result}"
  password                  = random_password.db_password.result
  volume_type               = var.volume_type
  volume_size_in_gb         = var.database_storage_size_gb
  encryption_at_rest        = true
  disable_backup            = false
  backup_schedule_frequency = 24 # every day
  backup_schedule_retention = 7  # keep it one week

  private_network {
    pn_id = var.private_network_id
  }

  dynamic "load_balancer" {
    for_each = var.enable_public_network ? [1] : []
    content {}
  }

  settings = var.database_settings
}

resource "scaleway_rdb_acl" "main" {
  instance_id = scaleway_rdb_instance.main.id

  dynamic "acl_rules" {
    for_each = var.database_allowed_ips
    content {
      ip = acl_rules.value
    }
  }
}