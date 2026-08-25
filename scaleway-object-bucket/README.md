# scaleway-object-bucket

Terraform module for a Scaleway Object Storage bucket with AES-256 encryption always enabled, plus optional static-website configuration and incomplete multipart-upload cleanup.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.4 |
| <a name="requirement_scaleway"></a> [scaleway](#requirement\_scaleway) | >= 2.37 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_scaleway"></a> [scaleway](#provider\_scaleway) | 2.81.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [scaleway_object_bucket.main](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/object_bucket) | resource |
| [scaleway_object_bucket_policy.main](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/object_bucket_policy) | resource |
| [scaleway_object_bucket_server_side_encryption_configuration.main](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/object_bucket_server_side_encryption_configuration) | resource |
| [scaleway_object_bucket_website_configuration.main](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/object_bucket_website_configuration) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_abort_incomplete_multipart_upload_days"></a> [abort\_incomplete\_multipart\_upload\_days](#input\_abort\_incomplete\_multipart\_upload\_days) | Days after which incomplete multipart uploads are aborted; null disables the lifecycle rule | `number` | `null` | no |
| <a name="input_acl"></a> [acl](#input\_acl) | Canned ACL to apply to the bucket; null leaves the provider default | `string` | `null` | no |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Globally unique Object Storage bucket name | `string` | n/a | yes |
| <a name="input_bucket_policy"></a> [bucket\_policy](#input\_bucket\_policy) | JSON bucket policy document; null leaves the bucket without a managed policy | `string` | `null` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Scaleway project ID associated with the bucket; null uses the provider default | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | Scaleway region in which to create the bucket | `string` | `"fr-par"` | no |
| <a name="input_website_enabled"></a> [website\_enabled](#input\_website\_enabled) | Whether to configure the bucket as a static website | `bool` | `false` | no |
| <a name="input_website_index_document"></a> [website\_index\_document](#input\_website\_index\_document) | Index document suffix used when website configuration is enabled | `string` | `"index.html"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_bucket_id"></a> [bucket\_id](#output\_bucket\_id) | Object Storage bucket ID |
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | Object Storage bucket name |
| <a name="output_bucket_policy_id"></a> [bucket\_policy\_id](#output\_bucket\_policy\_id) | Bucket policy ID when a policy is managed |
| <a name="output_server_side_encryption_id"></a> [server\_side\_encryption\_id](#output\_server\_side\_encryption\_id) | Regional ID of the bucket server-side encryption configuration |
| <a name="output_website_endpoint"></a> [website\_endpoint](#output\_website\_endpoint) | Static website endpoint when website configuration is enabled |
<!-- END_TF_DOCS -->