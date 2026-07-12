resource "scaleway_secret" "main" {
  name = "database--${var.database_name}"
}

resource "scaleway_secret_version" "latest" {
  secret_id = scaleway_secret.main.id
  data      = random_password.db_password.result
}