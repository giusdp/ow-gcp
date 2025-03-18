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
  # The provider's default region/zone can be overridden in the resources.
  region = "europe-west1"
  zone   = "europe-west1-b"
}

# Create a custom VPC network (global)
resource "google_compute_network" "ow_network" {
  name                    = "terraform-network"
  auto_create_subnetworks = false
}

# Create a subnetwork for europe-west1
resource "google_compute_subnetwork" "europe_subnet" {
  name          = "europe-subnet"
  ip_cidr_range = "10.128.0.0/20"
  region        = "europe-west1"
  network       = google_compute_network.ow_network.id
}

# Create a subnetwork for us-central1
resource "google_compute_subnetwork" "us_subnet" {
  name          = "us-subnet"
  ip_cidr_range = "10.128.16.0/20"
  region        = "us-central1"
  network       = google_compute_network.ow_network.id
}

# Firewall rule to allow SSH from anywhere
resource "google_compute_firewall" "ssh_rule" {
  name    = "ssh-enabled"
  network = google_compute_network.ow_network.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}


# Firewall rule to allow some ports to be accessed from anywhere
resource "google_compute_firewall" "phoenix_rule" {
  name    = "phoenix-enabled"
  network = google_compute_network.ow_network.name
  allow {
    protocol = "tcp"
    ports    = ["4000", "4021", "8089", "9090"]
  }
  source_ranges = ["0.0.0.0/0"]
}

# Firewall rule to allow internal traffic between instances
resource "google_compute_firewall" "internal" {
  name    = "internal-traffic"
  network = google_compute_network.ow_network.name
  allow {
    protocol = "all"
  }
  source_ranges = ["10.128.0.0/16"] # Adjust this if needed to cover both subnets.
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
    subnetwork = google_compute_subnetwork.europe_subnet.id
    access_config {} # For external IP
  }
  metadata = {
    ssh-keys = "${var.gc_user}:${file("../ow-gcp-key.pub")}"
  }
  tags = ["private"]
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
    subnetwork = google_compute_subnetwork.us_subnet.id
    access_config {} # For external IP
  }
  metadata = {
    ssh-keys = "${var.gc_user}:${file("../ow-gcp-key.pub")}"
  }
  tags = ["private"]
}

# Generate the hosts file for Ansible, using internal IPs for inter-node communication
resource "local_file" "hosts" {
  content = templatefile("hosts.tmpl",
    {
      eu_controller_ip = google_compute_instance.europe_vms["eu-controller"].network_interface.0.access_config.0.nat_ip
      eu_worker_ip     = google_compute_instance.europe_vms["eu-worker"].network_interface.0.access_config.0.nat_ip
      us_controller_ip = google_compute_instance.us_vms["us-controller"].network_interface.0.access_config.0.nat_ip
      us_worker_ip     = google_compute_instance.us_vms["us-worker"].network_interface.0.access_config.0.nat_ip
      # eu_private_worker_ip = google_compute_instance.europe_vms["eu-worker"].network_interface.0.network_ip
      # us_private_worker_ip = google_compute_instance.us_vms["us-worker"].network_interface.0.network_ip
      user = var.gc_user
    }
  )
  filename = "../ansible/hosts.ini"
}
