# Terraform module for GitHub Actions custom runner

Copyright (c) 2020-2021 [Antmicro](https://www.antmicro.com)

The aim of this project is to simplify the deployment of
[Antmicro's GitHub Actions runner](https://github.com/antmicro/runner)
and to describe the virtual resources according to IaC principles.

## Usage

In order to deploy the infrastructure,
make sure that the service account has the following roles assigned:

* **Compute Admin** for creating and managing resources within the Compute Engine.
* **Security Admin** for managing IAM policies.
* **Service Account Creator** for managing the service account linked with the coordinator instance.
* **Service Account User** for assigning the aforementioned service account to the coordinator instance.

Note that there is no explicit module-level parameter for passing the project name.
If you don't want Terraform to use the default value,
declare a provider, set the `project` argument and pass the provider as a [meta-argument](https://www.terraform.io/language/meta-arguments/module-providers) to the module declaration.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 3.53 |
| <a name="requirement_google-beta"></a> [google-beta](#requirement\_google-beta) | ~> 3.53 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | ~> 3.53 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_compute_attached_disk.gha-coordinator-logdisk-attached](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_attached_disk) | resource |
| [google_compute_attached_disk.gha-coordinator-persistentdisk-attached](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_attached_disk) | resource |
| [google_compute_attached_disk.gha-coordinator-sifimagedisk-attached](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_attached_disk) | resource |
| [google_compute_disk.gha-coordinator-bootdisk](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_disk) | resource |
| [google_compute_disk.gha-coordinator-logdisk](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_disk) | resource |
| [google_compute_disk.gha-coordinator-persistentdisk](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_disk) | resource |
| [google_compute_disk.gha-coordinator-sifimagedisk](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_disk) | resource |
| [google_compute_firewall.gha-firewall-allow-c-to-r](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.gha-firewall-allow-incoming-ssh](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.gha-firewall-allow-unbound](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.gha-firewall-drop-incoming-r-to-c](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_instance.gha-coordinator](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance) | resource |
| [google_compute_network.gha-network](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) | resource |
| [google_compute_router.gha-router](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router) | resource |
| [google_compute_router_nat.gha-nat](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_nat) | resource |
| [google_compute_subnetwork.gha-subnet](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_project_iam_member.gha-coordinator-sa-role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.gha-coordinator-sa-role-sa-user](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.gha-coordinator-sa-role-sm-accessor](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.gha-coordinator-sa-role-sm-viewer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_service_account.gha-coordinator-sa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_gcp_coordinator_disk_image"></a> [gcp\_coordinator\_disk\_image](#input\_gcp\_coordinator\_disk\_image) | Name of the image to use for coordinator boot disk | `string` | `"projects/debian-cloud/global/images/debian-10-buster-v20210512"` | no |
| <a name="input_gcp_coordinator_disk_name_prefix"></a> [gcp\_coordinator\_disk\_name\_prefix](#input\_gcp\_coordinator\_disk\_name\_prefix) | Defaults to instance name if not specified. | `string` | `null` | no |
| <a name="input_gcp_coordinator_disk_name_suffix"></a> [gcp\_coordinator\_disk\_name\_suffix](#input\_gcp\_coordinator\_disk\_name\_suffix) | String to append after instance name (useful for managing legacy deployments) | `string` | `"---boot-disk"` | no |
| <a name="input_gcp_coordinator_disk_size"></a> [gcp\_coordinator\_disk\_size](#input\_gcp\_coordinator\_disk\_size) | Runner coordinator boot disk size in gigabytes | `number` | `10` | no |
| <a name="input_gcp_coordinator_disk_type"></a> [gcp\_coordinator\_disk\_type](#input\_gcp\_coordinator\_disk\_type) | Runner coordinator boot disk type | `string` | `"pd-standard"` | no |
| <a name="input_gcp_coordinator_log_disk_present"></a> [gcp\_coordinator\_log\_disk\_present](#input\_gcp\_coordinator\_log\_disk\_present) | Specify if a sepearate disk for logs should be created and managed | `bool` | `false` | no |
| <a name="input_gcp_coordinator_log_disk_size"></a> [gcp\_coordinator\_log\_disk\_size](#input\_gcp\_coordinator\_log\_disk\_size) | Runner coordinator log disk size in gigabytes | `number` | `10` | no |
| <a name="input_gcp_coordinator_machine_type"></a> [gcp\_coordinator\_machine\_type](#input\_gcp\_coordinator\_machine\_type) | Runner coordinator machine type | `string` | `"n2-standard-4"` | no |
| <a name="input_gcp_coordinator_name"></a> [gcp\_coordinator\_name](#input\_gcp\_coordinator\_name) | Runner coordinator instance name | `string` | `"gha-runner-coordinator"` | no |
| <a name="input_gcp_coordinator_persistent_disk_present"></a> [gcp\_coordinator\_persistent\_disk\_present](#input\_gcp\_coordinator\_persistent\_disk\_present) | Specify if a sepearate disk for persistent data should be created and managed (beta) | `bool` | `false` | no |
| <a name="input_gcp_coordinator_persistent_disk_size"></a> [gcp\_coordinator\_persistent\_disk\_size](#input\_gcp\_coordinator\_persistent\_disk\_size) | Runner coordinator persistent disk size in gigabytes (beta) | `number` | `50` | no |
| <a name="input_gcp_coordinator_scale"></a> [gcp\_coordinator\_scale](#input\_gcp\_coordinator\_scale) | Number of runners that coordinator should enable (beta) | `number` | `"0"` | no |
| <a name="input_gcp_coordinator_sif_image_disk_present"></a> [gcp\_coordinator\_sif\_image\_disk\_present](#input\_gcp\_coordinator\_sif\_image\_disk\_present) | Specify if a sepearate disk for image should be attached (beta) | `bool` | `false` | no |
| <a name="input_gcp_coordinator_sif_image_name"></a> [gcp\_coordinator\_sif\_image\_name](#input\_gcp\_coordinator\_sif\_image\_name) | Name of the image containing sif image of the coordinator (beta) | `string` | `""` | no |
| <a name="input_gcp_sa_access_scope"></a> [gcp\_sa\_access\_scope](#input\_gcp\_sa\_access\_scope) | API access scope for coordinator service account | `string` | `"https://www.googleapis.com/auth/compute"` | no |
| <a name="input_gcp_service_account"></a> [gcp\_service\_account](#input\_gcp\_service\_account) | Name component of the service account for coordinator | `string` | `"gha-runner-coordinator-sa"` | no |
| <a name="input_gcp_subnet"></a> [gcp\_subnet](#input\_gcp\_subnet) | Name for VPC network and subnetwork | `string` | `"gha-runner-net"` | no |
| <a name="input_gcp_zone"></a> [gcp\_zone](#input\_gcp\_zone) | Zone where the coordinator instance, VPC resources and workers will be created | `string` | `"us-west1-a"` | no |

## Outputs

No outputs.
