locals {
  zone_no_sub = strrev(substr(strrev(var.gcp_zone), 2, -1))
}

resource "google_compute_network" "gha-network" {
  name                    = var.gcp_subnet
  project                 = var.gcp_project
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gha-subnet" {
  name    = var.gcp_subnet
  network = google_compute_network.gha-network.id
  region  = local.zone_no_sub
}
