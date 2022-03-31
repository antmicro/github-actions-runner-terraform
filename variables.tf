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

variable "gcp_project" {
  type        = string
  description = "Project name"
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
  description = "Name of the image to use for coordinator boot disk"
  default     = "projects/debian-cloud/global/images/debian-10-buster-v20210512"
}
