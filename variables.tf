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
