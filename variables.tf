variable "gcp_coordinator_name" {
  type        = string
  description = "Runner coordinator instance name"
  default     = "gha-runner-coordinator"
}

variable "gcp_coordinator_machine_type" {
  type        = string
  description = "Runner coordinator machine type"
  default     = "n2-standard-4"
}

variable "gcp_coordinator_disk_size" {
  type        = number
  description = "Runner coordinator boot disk size in gigabytes"
  default     = 10
}

variable "gcp_coordinator_disk_type" {
  type        = string
  description = "Runner coordinator boot disk type"
  default     = "pd-standard"
}

variable "gcp_coordinator_disk_name_prefix" {
  type        = string
  description = "Defaults to instance name if not specified."
  default     = null
  nullable    = true
}

variable "gcp_coordinator_disk_name_suffix" {
  type        = string
  description = "String to append after instance name (useful for managing legacy deployments)"
  default     = "---boot-disk"
}

variable "gcp_coordinator_log_disk_present" {
  type        = bool
  description = "Specify if a sepearate disk for logs should be created and managed"
  default     = false
}

variable "gcp_coordinator_log_disk_size" {
  type        = number
  description = "Runner coordinator log disk size in gigabytes"
  default     = 10
}

variable "gcp_zone" {
  type        = string
  description = "Zone where the coordinator instance, VPC resources and workers will be created"
  default     = "us-west1-a"
}

variable "gcp_auxiliary_zones" {
  type        = list(any)
  description = "A list of zones where workers can be spawned in case of home zone resource exhaustion (beta)"
  default     = []
}

variable "gcp_subnet" {
  type        = string
  description = "Name for VPC network and subnetwork"
  default     = "gha-runner-net"
}

variable "gcp_service_account" {
  type        = string
  description = "Name component of the service account for coordinator"
  default     = "gha-runner-coordinator-sa"
}

variable "gcp_sa_access_scope" {
  type        = string
  description = "API access scope for coordinator service account"
  default     = "https://www.googleapis.com/auth/compute"
}

variable "gcp_coordinator_disk_image" {
  type        = string
  description = "Name of the image to use for coordinator boot disk - cannot be changed"
  default     = "projects/debian-cloud/global/images/debian-10-buster-v20210512"
}

variable "gcp_coordinator_persistent_disk_size" {
  type        = number
  description = "Runner coordinator persistent disk size in gigabytes (beta)"
  default     = 50
}

variable "gcp_coordinator_persistent_disk_present" {
  type        = bool
  description = "Specify if a sepearate disk for persistent data should be created and managed (beta)"
  default     = false
}

variable "gcp_coordinator_sif_image_disk_present" {
  type        = bool
  description = "Specify if a sepearate disk for image should be attached (beta)"
  default     = false
}

variable "gcp_coordinator_sif_image_name" {
  type        = string
  description = "Name of the image containing sif image of the coordinator (beta)"
  default     = ""
}

variable "gcp_coordinator_scale" {
  type        = number
  description = "Number of runners that coordinator should enable (beta)"
  default     = "0"
}

variable "gcp_worker_image_name" {
  type        = string
  description = "Name of the image used for worker instances"
  default     = ""
}

variable "gcp_arm64_worker_image_name" {
  type        = string
  description = "Name of the image used for worker instances (ARM64)"
  default     = ""
}

variable "gcp_vpc_ipv6" {
  type        = bool
  description = "Enable external IPv6 access for worker machines"
  default     = false
}

variable "gcp_vpc_no_firewall" {
  type        = bool
  description = "Do not create firewall rules in the dedicated VPC network"
  default     = false
}

variable "gcp_coordinator_boot_image_update" {
  type        = string
  description = "Name of the image to use for updating coordinator boot disk"
  default     = ""
}

variable "gcp_boot_image_bucket_name" {
  type        = string
  description = "Name of the bucket used for uploading and storing boot images"
  default     = ""
}
