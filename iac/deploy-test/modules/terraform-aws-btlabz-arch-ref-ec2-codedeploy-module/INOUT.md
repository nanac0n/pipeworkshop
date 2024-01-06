# Terraform inputs and outputs.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12.0 |

## Providers

| Name | Version |
|------|---------|
| aws | n/a |
| random | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Code Deploy objects name prefix | `string` | `""` | no |
| tags | Additional tags. E.g. environment, backup tags etc | `map` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| app\_name | CodeDeploy Application Name |

