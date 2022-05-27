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
 * Note that there is no explicit module-level parameter for passing the project name.
 * If you don't want Terraform to use the default value, 
 * declare a provider, set the `project` argument and pass the provider as a [meta-argument](https://www.terraform.io/language/meta-arguments/module-providers) to the module declaration.
 */

locals {
  zone_no_sub    = strrev(substr(strrev(var.gcp_zone), 2, -1))
  log_disk_count = var.gcp_coordinator_log_disk_present == true ? 1 : 0
  sif_image_disk_count = var.gcp_coordinator_sif_image_disk_present == true ? 1 : 0
  persistent_disk_count = var.gcp_coordinator_persistent_disk_present == true ? 1 : 0
  c_tag          = "coordinator"
  r_tag          = "runners"
}

resource "google_compute_network" "gha-network" {
  name                    = var.gcp_subnet
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gha-subnet" {
  name          = var.gcp_subnet
  network       = google_compute_network.gha-network.id
  region        = local.zone_no_sub
  ip_cidr_range = "10.0.0.0/16"
}

resource "google_compute_firewall" "gha-firewall-allow-unbound" {
  name        = "${var.gcp_subnet}---allow-coordinator-services"
  network     = google_compute_network.gha-network.id
  direction   = "INGRESS"
  priority    = 999
  target_tags = [local.c_tag]
  source_tags = [local.r_tag]

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

  allow {
    protocol = "all"
  }
}

resource "google_compute_router" "gha-router" {
  name    = "${var.gcp_subnet}---cloud-router"
  network = google_compute_network.gha-network.id
  region  = local.zone_no_sub
}

resource "google_compute_router_nat" "gha-nat" {
  name                               = "${var.gcp_subnet}---gateway"
  router                             = google_compute_router.gha-router.name
  region                             = local.zone_no_sub
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  min_ports_per_vm                   = 512
}

resource "google_service_account" "gha-coordinator-sa" {
  account_id   = var.gcp_service_account
  display_name = "SA for GHA Runner"
}

resource "google_project_iam_member" "gha-coordinator-sa-role" {
  role    = "roles/compute.admin"
  member  = "serviceAccount:${google_service_account.gha-coordinator-sa.email}"
}

resource "google_project_iam_member" "gha-coordinator-sa-role-sa-user" {
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.gha-coordinator-sa.email}"
}

resource "google_project_iam_member" "gha-coordinator-sa-role-sm-viewer" {
  role    = "roles/secretmanager.viewer"
  member  = "serviceAccount:${google_service_account.gha-coordinator-sa.email}"
}

resource "google_project_iam_member" "gha-coordinator-sa-role-sm-accessor" {
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.gha-coordinator-sa.email}"
}

resource "google_compute_disk" "gha-coordinator-bootdisk" {
  name    = format("%s%s", coalesce(var.gcp_coordinator_disk_name_prefix, var.gcp_coordinator_name), var.gcp_coordinator_disk_name_suffix)
  size    = var.gcp_coordinator_disk_size
  zone    = var.gcp_zone
  type    = var.gcp_coordinator_disk_type
  image   = var.gcp_coordinator_disk_image
}

resource "google_compute_disk" "gha-coordinator-logdisk" {
  name    = "${var.gcp_coordinator_name}--logs"
  size    = var.gcp_coordinator_log_disk_size
  zone    = var.gcp_zone
  count   = local.log_disk_count
}

resource "google_compute_attached_disk" "gha-coordinator-logdisk-attached" {
  device_name = "gharunnerlogs"
  disk        = google_compute_disk.gha-coordinator-logdisk[count.index].id
  instance    = google_compute_instance.gha-coordinator.id
  count       = local.log_disk_count
}

resource "google_compute_disk" "gha-coordinator-persistentdisk" {
  name    = "${var.gcp_coordinator_name}--persistent"
  size    = var.gcp_coordinator_persistent_disk_size
  zone    = var.gcp_zone
  count   = local.persistent_disk_count
}

resource "google_compute_attached_disk" "gha-coordinator-persistentdisk-attached" {
  device_name = "gharunnerpersistentdisk"
  disk        = google_compute_disk.gha-coordinator-persistentdisk[count.index].id
  instance    = google_compute_instance.gha-coordinator.id
  count       = local.persistent_disk_count
}

resource "google_compute_disk" "gha-coordinator-sifimagedisk" {
  name    = "${var.gcp_coordinator_name}--sifimage"
  size    = 10
  zone    = var.gcp_zone
  image   = var.gcp_coordinator_sif_image_name
  count   = local.sif_image_disk_count
}

resource "google_compute_attached_disk" "gha-coordinator-sifimagedisk-attached" {
  device_name = "gharunnersifimagedisk"
  disk        = google_compute_disk.gha-coordinator-sifimagedisk[count.index].id
  instance    = google_compute_instance.gha-coordinator.id
  mode        = "READ_ONLY"
  count       = local.sif_image_disk_count
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
    scopes = [var.gcp_sa_access_scope]
  }

  lifecycle {
    ignore_changes = [
      attached_disk,
      metadata["ssh-keys"]
    ]
  }

  metadata = {
    SCALE = var.gcp_coordinator_scale > 0 ? var.gcp_coordinator_scale : null
  }

  deletion_protection = true
}
