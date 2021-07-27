variable "gcp_coordinator_name" {
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

variable "gcp_service_account" {
  type = string
}
