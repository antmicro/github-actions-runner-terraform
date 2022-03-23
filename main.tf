/**
 * # Terraform module for GitHub Actions custom runner
 *
 * Copyright (c) 2020-2021 [Antmicro](https://www.antmicro.com)
 *
 * The aim of this project is to simplify the deployment of 
 * [Antmicro's GitHub Actions runner](https://github.com/antmicro/runner)
 * and to describe the virtual resources according to IaC principles.
 * 
 * ## Usage
 *
 * In order to deploy the infrastructure, 
 * make sure that the service account has the following roles assigned:
 * 
 * * **Compute Admin** for creating and managing resources within the Compute Engine.
 * * **Security Admin** for managing IAM policies.
 * * **Service Account Creator** for managing the service account linked with the coordinator instance.
 * * **Service Account User** for assigning the aforementioned service account to the coordinator instance.
 *
 *
 */

locals {
  zone_no_sub    = strrev(substr(strrev(var.gcp_zone), 2, -1))
  log_disk_count = var.gcp_coordinator_log_disk_present == true ? 1 : 0
  c_tag          = "coordinator"
  r_tag          = "runners"
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
  ip_cidr_range = "10.0.0.0/16"
  project       = var.gcp_project
}

resource "google_compute_firewall" "gha-firewall-allow-unbound" {
  name        = "${var.gcp_subnet}---allow-coordinator-services"
  network     = google_compute_network.gha-network.id
  direction   = "INGRESS"
  priority    = 999
  target_tags = [local.c_tag]
  source_tags = [local.r_tag]
  project     = var.gcp_project

  allow {
    protocol = "udp"
    ports    = [53, 5140]
  }
  allow {
    protocol = "tcp"
    ports    = [5000]
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

resource "google_compute_firewall" "gha-firewall-allow-c-to-r" {
  name        = "${var.gcp_subnet}---access-runners"
  network     = google_compute_network.gha-network.id
  direction   = "INGRESS"
  priority    = 1000
  target_tags = [local.r_tag]
  source_tags = [local.c_tag]
  project     = var.gcp_project

  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "gha-firewall-allow-incoming-ssh" {
  name          = "${var.gcp_subnet}---ssh-from-outside"
  network       = google_compute_network.gha-network.id
  direction     = "INGRESS"
  priority      = 1001
  target_tags   = [local.c_tag]
  source_ranges = ["0.0.0.0/0"]
  project       = var.gcp_project

  allow {
    protocol = "all"
  }
}

resource "google_compute_router" "gha-router" {
  name    = "${var.gcp_subnet}---cloud-router"
  network = google_compute_network.gha-network.id
  region  = local.zone_no_sub
  project = var.gcp_project
}

resource "google_compute_router_nat" "gha-nat" {
  name                               = "${var.gcp_subnet}---gateway"
  router                             = google_compute_router.gha-router.name
  region                             = local.zone_no_sub
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  min_ports_per_vm                   = 512
  project                            = var.gcp_project
}

resource "google_service_account" "gha-coordinator-sa" {
  account_id   = var.gcp_service_account
  display_name = "SA for GHA Runner"
  project      = var.gcp_project
}

resource "google_project_iam_member" "gha-coordinator-sa-role" {
  role    = "roles/compute.admin"
  member  = "serviceAccount:${google_service_account.gha-coordinator-sa.email}"
  project = var.gcp_project
}

resource "google_compute_disk" "gha-coordinator-bootdisk" {
  name    = format("%s%s", coalesce(var.gcp_coordinator_disk_name_prefix, var.gcp_coordinator_name), var.gcp_coordinator_disk_name_suffix)
  size    = var.gcp_coordinator_disk_size
  zone    = var.gcp_zone
  type    = var.gcp_coordinator_disk_type
  image   = "projects/debian-cloud/global/images/debian-10-buster-v20210512"
  project = var.gcp_project
}

resource "google_compute_disk" "gha-coordinator-logdisk" {
  name    = "${var.gcp_coordinator_name}--logs"
  size    = var.gcp_coordinator_log_disk_size
  zone    = var.gcp_zone
  project = var.gcp_project
  count   = local.log_disk_count
}

resource "google_compute_attached_disk" "gha-coordinator-logdisk-attached" {
  device_name = "gharunnerlogs"
  disk        = google_compute_disk.gha-coordinator-logdisk[count.index].id
  instance    = google_compute_instance.gha-coordinator.id
  count       = local.log_disk_count
}

resource "google_compute_instance" "gha-coordinator" {
  name         = var.gcp_coordinator_name
  zone         = var.gcp_zone
  machine_type = var.gcp_coordinator_machine_type

  labels = {
    isantmicrorunner = 1
  }

  tags = ["coordinator"]

  boot_disk {
    auto_delete = true
    source      = google_compute_disk.gha-coordinator-bootdisk.name
  }

  network_interface {
    network    = google_compute_network.gha-network.id
    subnetwork = google_compute_subnetwork.gha-subnet.id

    access_config {}
  }

  service_account {
    email  = google_service_account.gha-coordinator-sa.email
    scopes = ["https://www.googleapis.com/auth/compute"]
  }

  lifecycle {
    ignore_changes = [
      attached_disk,
      metadata["ssh-keys"]
    ]
  }

  project = var.gcp_project
  deletion_protection = true
}
