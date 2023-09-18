/**
 * # Terraform module for GitHub Actions custom runner
 *
 * Copyright (c) 2020-2023 [Antmicro](https://www.antmicro.com)
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
 * * **Service Usage Admin** for enabling the necessary APIs.
 * * (optional) **Storage Admin** for managing GCS buckets for data archiving purposes e.g. storing job logs.
 *
 * Note that there is no explicit module-level parameter for passing the project name.
 * If you don't want Terraform to use the default value, 
 * declare a provider, set the `project` argument and pass the provider as a [meta-argument](https://www.terraform.io/language/meta-arguments/module-providers) to the module declaration.
 *
 * ## Long-term usage considerations
 *
 * Changing certain parameters after the module has been applied may result
 * in the necessity to recreate one or more resources.
 * This section is an attempt to document these scenarios.
 *
 * ### Enabling or disabling IPv6 support
 *
 * Changing the `gcp_vpc_ipv6` variable will always result in recreation of all subnetworks.
 * That's because it is not possible to edit the stack type (IPv4 only or dual stack) of the subnetwork
 * after it has been created.
 * Therefore, in order to change this particular parameter of a subnetwork, it is necessary to first
 * remove it and create it again.
 *
 * For this operation to succeed, the following preconditions must be true:
 * * no worker instance may be running
 * * the coordinator instance must be stopped
 * * the network associated with the coordinator instance must be changed to something else (e.g. default)
 *
 */

locals {
  zone_no_sub           = strrev(substr(strrev(var.gcp_zone), 2, -1))
  regions               = concat([local.zone_no_sub], var.gcp_auxiliary_zones)
  log_disk_count        = var.gcp_coordinator_log_disk_present == true ? 1 : 0
  log_bucket_count      = var.gcp_log_bucket_name != null ? 1 : 0
  sif_image_disk_count  = var.gcp_coordinator_sif_image_disk_present == true ? 1 : 0
  persistent_disk_count = var.gcp_coordinator_persistent_disk_present == true ? 1 : 0
  fw_count              = var.gcp_vpc_no_firewall == false ? 1 : 0
  static_ip_count       = var.gcp_coordinator_reserve_static_internal_ip ? 1 : 0
  c_tag                 = "coordinator"
  r_tag                 = "runners"

  // Reserve the second host of the first subnetwork (indexed from zero)
  // as the first host of a given subnet is used as its default gateway, e.g.:
  //
  // > cidrsubnet("10.3.0.0/16", 2, 0)
  // "10.3.0.0/18"
  //
  // > cidrhost(cidrsubnet("10.3.0.0/16", 2, 0), 2)
  // "10.3.0.2"
  //
  coordinator_static_ip = var.gcp_coordinator_reserve_static_internal_ip ? cidrhost(cidrsubnet(var.gcp_vpc_prefix, var.gcp_vpc_newbits, 0), 2) : null
}

data "google_project" "project" {}

resource "google_project_service" "iam-api" {
  service = "iam.googleapis.com"
}

resource "google_project_service" "compute-engine-api" {
  service = "compute.googleapis.com"
}

resource "google_project_service" "storage-api" {
  service = "storage.googleapis.com"
  count   = local.log_bucket_count
}

resource "google_compute_network" "gha-network" {
  name                    = var.gcp_subnet
  auto_create_subnetworks = false
  depends_on = [
    google_project_service.compute-engine-api
  ]
}

resource "google_compute_subnetwork" "gha-subnet" {
  count         = length(local.regions)
  name          = count.index > 0 ? "${var.gcp_subnet}-aux-${count.index}" : var.gcp_subnet
  network       = google_compute_network.gha-network.id
  region        = local.regions[count.index]
  ip_cidr_range = cidrsubnet(var.gcp_vpc_prefix, var.gcp_vpc_newbits, count.index)

  stack_type       = var.gcp_vpc_ipv6 == true ? "IPV4_IPV6" : "IPV4_ONLY"
  ipv6_access_type = var.gcp_vpc_ipv6 == true ? "EXTERNAL" : null
}

moved {
  from = google_compute_subnetwork.gha-subnet
  to   = google_compute_subnetwork.gha-subnet[0]
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

  count = local.fw_count
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

  count = local.fw_count
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

  count = local.fw_count
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

  count = local.fw_count
}

resource "google_compute_router" "gha-router" {
  count   = length(local.regions)
  name    = count.index > 0 ? "${var.gcp_subnet}---cloud-router-${count.index}" : "${var.gcp_subnet}---cloud-router"
  network = google_compute_network.gha-network.id
  region  = local.regions[count.index]
}

moved {
  from = google_compute_subnetwork.gha-router
  to   = google_compute_subnetwork.gha-router[0]
}

resource "google_compute_router_nat" "gha-nat" {
  count                              = length(google_compute_router.gha-router)
  name                               = count.index > 0 ? "${var.gcp_subnet}---gateway-${count.index}" : "${var.gcp_subnet}---gateway"
  router                             = google_compute_router.gha-router[count.index].name
  region                             = google_compute_router.gha-router[count.index].region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  min_ports_per_vm                   = 512
}

moved {
  from = google_compute_router_nat.gha-nat
  to   = google_compute_router_nat.gha-nat[0]
}

resource "google_service_account" "gha-coordinator-sa" {
  account_id   = var.gcp_service_account
  display_name = "SA for GHA Runner"
  depends_on = [
    google_project_service.iam-api
  ]
}

resource "google_project_iam_member" "gha-coordinator-sa-role" {
  role    = "roles/compute.admin"
  member  = "serviceAccount:${google_service_account.gha-coordinator-sa.email}"
  project = data.google_project.project.project_id
}

resource "google_project_iam_member" "gha-coordinator-sa-role-sa-user" {
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.gha-coordinator-sa.email}"
  project = data.google_project.project.project_id
}

resource "google_project_iam_member" "gha-coordinator-sa-role-sm-viewer" {
  role    = "roles/secretmanager.viewer"
  member  = "serviceAccount:${google_service_account.gha-coordinator-sa.email}"
  project = data.google_project.project.project_id
}

resource "google_project_iam_member" "gha-coordinator-sa-role-sm-accessor" {
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.gha-coordinator-sa.email}"
  project = data.google_project.project.project_id
}

resource "google_compute_disk" "gha-coordinator-bootdisk" {
  name  = format("%s%s", coalesce(var.gcp_coordinator_disk_name_prefix, var.gcp_coordinator_name), var.gcp_coordinator_disk_name_suffix)
  size  = var.gcp_coordinator_disk_size
  zone  = var.gcp_zone
  type  = var.gcp_coordinator_disk_type
  image = var.gcp_coordinator_disk_image
  depends_on = [
    google_project_service.compute-engine-api
  ]
}

resource "google_compute_disk" "gha-coordinator-logdisk" {
  name  = "${var.gcp_coordinator_name}--logs"
  size  = var.gcp_coordinator_log_disk_size
  zone  = var.gcp_zone
  count = local.log_disk_count
  depends_on = [
    google_project_service.compute-engine-api
  ]
}

resource "google_compute_attached_disk" "gha-coordinator-logdisk-attached" {
  device_name = "gharunnerlogs"
  disk        = google_compute_disk.gha-coordinator-logdisk[count.index].id
  instance    = google_compute_instance.gha-coordinator.id
  count       = local.log_disk_count
}

resource "google_compute_disk" "gha-coordinator-persistentdisk" {
  name  = "${var.gcp_coordinator_name}--persistent"
  size  = var.gcp_coordinator_persistent_disk_size
  zone  = var.gcp_zone
  count = local.persistent_disk_count
  depends_on = [
    google_project_service.compute-engine-api
  ]
}

resource "google_compute_attached_disk" "gha-coordinator-persistentdisk-attached" {
  device_name = "gharunnerpersistentdisk"
  disk        = google_compute_disk.gha-coordinator-persistentdisk[count.index].id
  instance    = google_compute_instance.gha-coordinator.id
  count       = local.persistent_disk_count
}

resource "google_compute_disk" "gha-coordinator-sifimagedisk" {
  name  = "${var.gcp_coordinator_name}--sifimage"
  size  = 10
  zone  = var.gcp_zone
  image = var.gcp_coordinator_sif_image_name
  count = local.sif_image_disk_count
  depends_on = [
    google_project_service.compute-engine-api
  ]
}

resource "google_compute_attached_disk" "gha-coordinator-sifimagedisk-attached" {
  device_name = "gharunnersifimagedisk"
  disk        = google_compute_disk.gha-coordinator-sifimagedisk[count.index].id
  instance    = google_compute_instance.gha-coordinator.id
  mode        = "READ_ONLY"
  count       = local.sif_image_disk_count
}

resource "google_compute_address" "gha-coordinator-static-ip" {
  name         = "${var.gcp_coordinator_name}--ip"
  subnetwork   = google_compute_subnetwork.gha-subnet[0].self_link
  address_type = "INTERNAL"
  region       = local.regions[0]
  address      = local.coordinator_static_ip
  count        = local.static_ip_count
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
    network_ip = var.gcp_coordinator_reserve_static_internal_ip ? google_compute_address.gha-coordinator-static-ip[0].address : null
    subnetwork = google_compute_subnetwork.gha-subnet[0].id

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
    SCALE              = var.gcp_coordinator_scale > 0 ? var.gcp_coordinator_scale : null
    WORKER_IMAGE       = var.gcp_worker_image_name != "" ? var.gcp_worker_image_name : null
    WORKER_IMAGE_ARM64 = var.gcp_arm64_worker_image_name != "" ? var.gcp_arm64_worker_image_name : null
    # it has to be set, otherwise wait_for_change will return error
    BOOT_IMAGE_UPDATE = var.gcp_coordinator_boot_image_update
    BOOT_IMAGE_BUCKET = var.gcp_boot_image_bucket_name != "" ? var.gcp_boot_image_bucket_name : null
    LOG_BUCKET_NAME   = var.gcp_log_bucket_name
    BRV_URL           = var.gcp_build_results_viewer_url != "" ? var.gcp_build_results_viewer_url : null
    BRV_PUBLIC_URL    = var.gcp_build_results_viewer_public_url != "" ? var.gcp_build_results_viewer_public_url : null
  }

  deletion_protection = true

  depends_on = [
    google_project_service.compute-engine-api
  ]
}

resource "google_storage_bucket" "gha-log-bucket" {
  count    = local.log_bucket_count
  name     = var.gcp_log_bucket_name
  location = local.zone_no_sub

  storage_class = "REGIONAL"

  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true

  depends_on = [
    google_project_service.storage-api
  ]
}

resource "google_storage_bucket_iam_member" "gha-coordinator-sa-role-bucket-creator" {
  bucket = google_storage_bucket.gha-log-bucket[count.index].name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.gha-coordinator-sa.email}"

  depends_on = [
    google_storage_bucket.gha-log-bucket
  ]

  count = local.log_bucket_count
}

output "coordinator_sa" {
  value       = google_service_account.gha-coordinator-sa.email
  description = "The email address of the service account assigned to the coordinator machine"
}

output "coordinator_static_ip" {
  value       = local.coordinator_static_ip
  description = "Static IP address of the coordinator machine (null if ephemeral)"
}

output "coordinator_vpc_self_link" {
  value       = google_compute_network.gha-network.self_link
  description = "Self-link to the VPC network of the deployment"
}
