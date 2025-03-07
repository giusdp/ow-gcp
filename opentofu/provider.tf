terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.5.0"
    }
  }
}

variable "project" {}
variable "gc_user" {}
variable "allowed_ip" {}

variable "belgium_vms" {
  type = map(string)

  default = {
    eu-controller = "e2-medium"
    eu-worker     = "e2-medium"
  }
}

variable "us_vms" {
  type = map(string)

  default = {
    us-controller = "e2-medium"
    us-worker     = "e2-medium"
  }
}

provider "google" {
  credentials = file("credentials.json")
  project     = var.project
  region      = "europe-west1"
  zone        = "europe-west1-b"
}

resource "google_compute_network" "ow_network" {
  name = "terraform-network"
}

resource "google_compute_firewall" "ssh-rule" {
  name    = "ssh-enabled"
  network = google_compute_network.ow_network.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "private-ports" {
  name    = "private-all-enabled"
  network = google_compute_network.ow_network.name
  allow {
    protocol = "all"
    # ports    = ["6443"]
  }
  source_tags = ["private"]
}

# Belgium VMs (controller and worker)
resource "google_compute_instance" "europe_vms" {
  for_each     = var.belgium_vms
  name         = each.key
  zone         = "europe-west1-b"
  machine_type = each.value
  boot_disk {
    initialize_params {
      size  = 80
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
    }
  }
  network_interface {
    network = google_compute_network.ow_network.name
    access_config {}
  }
  metadata = { ssh-keys = "${var.gc_user}:${file("../ow-gcp-key.pub")}" }
  tags     = ["private"]
}

# US VMs (controller and worker)
resource "google_compute_instance" "us_vms" {
  for_each     = var.us_vms
  name         = each.key
  zone         = "us-central1-a"
  machine_type = each.value
  boot_disk {
    initialize_params {
      size  = 40
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
    }
  }
  network_interface {
    network = google_compute_network.ow_network.name
    access_config {}
  }
  metadata = { ssh-keys = "${var.gc_user}:${file("../ow-gcp-key.pub")}" }
  tags     = ["private"]
}

resource "local_file" "hosts" {
  content = templatefile("hosts.tmpl",
    {
      eu_controller_ip     = google_compute_instance.europe_vms["eu-controller"].network_interface.0.access_config.0.nat_ip
      eu_worker_ip         = google_compute_instance.europe_vms["eu-worker"].network_interface.0.access_config.0.nat_ip
      eu_private_worker_ip = google_compute_instance.europe_vms["eu-worker"].network_interface.0.network_ip
      us_controller_ip     = google_compute_instance.us_vms["us-controller"].network_interface.0.access_config.0.nat_ip
      us_worker_ip         = google_compute_instance.us_vms["us-worker"].network_interface.0.access_config.0.nat_ip
      us_private_worker_ip = google_compute_instance.us_vms["us-worker"].network_interface.0.network_ip
      user                 = var.gc_user
    }
  )
  filename = "../ansible/hosts.ini"
}
