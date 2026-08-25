resource "scaleway_object_bucket" "main" {
  name   = var.bucket_name
  region = var.region
  acl    = var.acl

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
