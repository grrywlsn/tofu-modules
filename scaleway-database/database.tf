resource "random_uuid" "db_username" {
  count = var.create_user && var.database_user_name == null ? 1 : 0
}

resource "random_password" "db_password" {
  count = var.create_user && var.database_user_password == null ? 1 : 0

  length           = 30
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 1
  override_special = "!"
}

locals {
  # Use ternaries (not coalesce) so we never index empty count-0 random resources.
  database_user_name = var.create_user ? (
    var.database_user_name != null ? var.database_user_name : random_uuid.db_username[0].result
  ) : var.database_user_name
  database_user_password = var.create_user ? (
    var.database_user_password != null ? var.database_user_password : random_password.db_password[0].result
  ) : null
  privilege_user_name     = var.create_user ? local.database_user_name : var.database_user_name
  privilege_database_name = var.create_database ? scaleway_rdb_database.main[0].name : var.database_name
}

resource "scaleway_rdb_database" "main" {
  count = var.create_database ? 1 : 0

  instance_id = var.database_instance_id
  name        = var.database_name
}

resource "scaleway_rdb_user" "db_user" {
  count = var.create_user ? 1 : 0

  instance_id = var.database_instance_id
  name        = local.database_user_name
  password    = local.database_user_password
  is_admin    = var.database_user_is_admin
}

resource "scaleway_rdb_privilege" "main" {
  count = var.create_privilege ? 1 : 0

  instance_id   = var.database_instance_id
  user_name     = local.privilege_user_name
  database_name = local.privilege_database_name
  permission    = var.database_privilege_permission

  depends_on = [
    scaleway_rdb_user.db_user,
    scaleway_rdb_database.main,
  ]
}
