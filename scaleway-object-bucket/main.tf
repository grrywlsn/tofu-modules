resource "scaleway_object_bucket" "main" {
  name       = var.bucket_name
  region     = var.region
  project_id = var.project_id
  acl        = var.acl

  dynamic "lifecycle_rule" {
    for_each = var.abort_incomplete_multipart_upload_days == null ? [] : [var.abort_incomplete_multipart_upload_days]

    content {
      id                                     = "abort-incomplete-multipart-uploads"
      enabled                                = true
      abort_incomplete_multipart_upload_days = lifecycle_rule.value
    }
  }
}

resource "scaleway_object_bucket_website_configuration" "main" {
  count = var.website_enabled ? 1 : 0

  bucket = scaleway_object_bucket.main.id

  index_document {
    suffix = var.website_index_document
  }
}

resource "scaleway_object_bucket_server_side_encryption_configuration" "main" {
  bucket     = scaleway_object_bucket.main.name
  region     = var.region
  project_id = var.project_id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "scaleway_object_bucket_policy" "main" {
  count = var.bucket_policy == null ? 0 : 1

  bucket     = scaleway_object_bucket.main.id
  region     = var.region
  project_id = var.project_id
  policy     = var.bucket_policy
}
