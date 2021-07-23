locals {
  zone_no_sub = strrev(substr(strrev(var.gcp_zone), 2, -1))
  c_tag       = "coordinator"
  r_tag       = "runners"
}

resource "google_compute_network" "gha-network" {
  name                    = var.gcp_subnet
  project                 = var.gcp_project
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gha-subnet" {
  name          = var.gcp_subnet
  network       = google_compute_network.gha-network.id
  region        = local.zone_no_sub
  ip_cidr_range = "10.0.0.0/24"
  project       = var.gcp_project
}

resource "google_compute_firewall" "gha-firewall-allow-unbound" {
  name        = "${var.gcp_subnet}--coordinator-dns"
  network     = google_compute_network.gha-network.id
  direction   = "INGRESS"
  priority    = 999
  target_tags = [local.c_tag]
  source_tags = [local.r_tag]
  project     = var.gcp_project

  allow {
    protocol = "udp"
    ports    = [53]
  }
}

resource "google_compute_firewall" "gha-firewall-drop-incoming-r-to-c" {
  name        = "${var.gcp_subnet}---deny-access-coordinator"
  network     = google_compute_network.gha-network.id
  direction   = "INGRESS"
  priority    = 1000
  target_tags = [local.c_tag]
  source_tags = [local.r_tag]
  project     = var.gcp_project

  # TODO: This might be erroneous, take a look at it later.
  allow {
    protocol = "all"
  }
}
