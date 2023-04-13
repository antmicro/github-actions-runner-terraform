provider "google" {
}

module "gha-test-runner" {
  source                  = "../"
  gcp_coordinator_name    = "gh-actions-runner"
  gcp_zone                = "europe-west4-a"
  gcp_project             = "my-cool-project"
  gcp_subnet              = "gh-actions-runner-net"
  gcp_service_account     = "gh-actions-runner-sa"
  gcp_log_bucket_name     = "gh-actions-log-bucket"
  gcp_log_bucket_location = "europe-west4"
}
