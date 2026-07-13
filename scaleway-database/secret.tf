resource "scaleway_secret" "main" {
  count = var.store_password_in_secret_manager && var.create_user ? 1 : 0

  # Include username so multiple users on the same logical database do not collide.
  name = "database--${var.database_name}--${local.database_user_name}"
}

locals {
  database_url = var.database_hostname != null ? format(
    "postgresql://%s:%s@%s:%d/%s",
    urlencode(local.database_user_name),
    urlencode(local.database_user_password),
    var.database_hostname,
    var.database_port,
    var.database_name,
  ) : null

  # JSON keys for External Secrets dataFrom.extract → Kubernetes Secret.
  secret_manager_env = {
    DATABASE_HOST     = var.database_hostname
    DATABASE_PORT     = tostring(var.database_port)
    DATABASE_NAME     = var.database_name
    DATABASE_USER     = local.database_user_name
    DATABASE_PASSWORD = local.database_user_password
    DATABASE_URL      = local.database_url
    PGHOST            = var.database_hostname
    PGPORT            = tostring(var.database_port)
    PGDATABASE        = var.database_name
    PGUSER            = local.database_user_name
    PGPASSWORD        = local.database_user_password
    POSTGRES_HOST     = var.database_hostname
    POSTGRES_PORT     = tostring(var.database_port)
    POSTGRES_DB       = var.database_name
    POSTGRES_USER     = local.database_user_name
    POSTGRES_PASSWORD = local.database_user_password
  }
}

resource "scaleway_secret_version" "latest" {
  count = var.store_password_in_secret_manager && var.create_user ? 1 : 0

  secret_id = scaleway_secret.main[0].id
  data      = jsonencode(local.secret_manager_env)
}
