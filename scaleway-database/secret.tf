resource "scaleway_secret" "main" {
  count = var.store_password_in_secret_manager && var.create_user ? 1 : 0

  # Include username so multiple users on the same logical database do not collide.
  name = "database--${var.database_name}--${local.database_user_name}"
}

resource "scaleway_secret_version" "latest" {
  count = var.store_password_in_secret_manager && var.create_user ? 1 : 0

  secret_id = scaleway_secret.main[0].id
  data      = local.database_user_password
}
