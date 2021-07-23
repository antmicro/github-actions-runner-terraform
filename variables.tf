variable "gha_instances_num" {
  type = number
}

variable "gha_repository" {
  type = string
}

variable "gcp_coordinator_name" {
  type = string
}

variable "gcp_worker" {
  type = string
}

variable "gcp_zone" {
  type    = string
  default = "us-west1-a"
}

variable "gcp_project" {
  type = string
}

variable "gcp_subnet" {
  type = string
}

variable "gcp_image" {
  type = string
}

variable "gcp_service_account" {
  type = string
}

variable "gcp_disk_type" {
  type    = string
  default = "pd-ssd"
}

variable "gcp_disk_size" {
  type    = number
  default = 30
}
