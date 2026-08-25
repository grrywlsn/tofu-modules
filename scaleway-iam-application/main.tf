resource "scaleway_iam_application" "main" {
  name = var.application_name
}

resource "scaleway_iam_api_key" "main" {
  application_id     = scaleway_iam_application.main.id
  description        = coalesce(var.api_key_description, var.application_name)
  default_project_id = var.project_id
}

resource "scaleway_iam_policy" "main" {
  name           = var.policy_name
  description    = var.policy_description
  application_id = scaleway_iam_application.main.id

  rule {
    project_ids          = [var.project_id]
    permission_set_names = var.permission_set_names
  }
}
