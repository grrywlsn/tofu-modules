# scaleway-iam-application

Terraform module for a Scaleway IAM application, API key, and project-scoped permission policy.

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
| [scaleway_iam_api_key.main](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/iam_api_key) | resource |
| [scaleway_iam_application.main](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/iam_application) | resource |
| [scaleway_iam_policy.main](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/iam_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_api_key_description"></a> [api\_key\_description](#input\_api\_key\_description) | Description attached to the IAM API key; null uses the application name | `string` | `null` | no |
| <a name="input_application_name"></a> [application\_name](#input\_application\_name) | IAM application name | `string` | n/a | yes |
| <a name="input_permission_set_names"></a> [permission\_set\_names](#input\_permission\_set\_names) | Scaleway permission sets granted to the application in the project | `list(string)` | n/a | yes |
| <a name="input_policy_description"></a> [policy\_description](#input\_policy\_description) | IAM policy description | `string` | `null` | no |
| <a name="input_policy_name"></a> [policy\_name](#input\_policy\_name) | IAM policy name | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Scaleway project used by the API key and IAM policy | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_access_key"></a> [access\_key](#output\_access\_key) | IAM API access key ID |
| <a name="output_application_id"></a> [application\_id](#output\_application\_id) | IAM application ID |
| <a name="output_policy_id"></a> [policy\_id](#output\_policy\_id) | IAM policy ID |
| <a name="output_secret_key"></a> [secret\_key](#output\_secret\_key) | IAM API secret key |
<!-- END_TF_DOCS -->