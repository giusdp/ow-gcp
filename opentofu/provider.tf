terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.5.0"
    }
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

variable "project" {}
variable "gc_user" {}
variable "allowed_ip" {}
variable "do_token" {}

provider "digitalocean" {
  token = var.do_token
}

# Create the edge controller on digitalocean
resource "digitalocean_droplet" "edge_controller" {
  image    = "ubuntu-20-04-x64"
  name     = "edgecontroller"
  region   = "fra1"
  size     = "s-2vcpu-4gb"
  ssh_keys = [40852984]
  tags     = ["edge"]
}

# Create the edge worker on digitalocean
resource "digitalocean_droplet" "edge_worker" {
  image    = "ubuntu-20-04-x64"
  name     = "edgeworker"
  region   = "fra1"
  size     = "s-2vcpu-4gb"
  ssh_keys = [40852984]
  tags     = ["edge"]
}

# Create the edge broker on digitalocean
resource "digitalocean_droplet" "edge_broker" {
  image    = "ubuntu-20-04-x64"
  name     = "broker"
  region   = "fra1"
  size     = "s-2vcpu-4gb"
  ssh_keys = [40852984]
  tags     = ["edge"]
}


variable "belgium_vms" {
  type = map(string)

  default = {
    controller = "e2-medium"
    worker     = "e2-medium"
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

resource "google_compute_firewall" "ow-invoke-rule" {
  name    = "ow-invoke-enabled"
  network = google_compute_network.ow_network.name
  allow {
    protocol = "tcp"
    ports    = ["31001"]
  }
  source_ranges = ["${var.allowed_ip}"]
}

resource "google_compute_firewall" "openvpn-rule" {
  name    = "openvpn-server-allow"
  network = google_compute_network.ow_network.name
  allow {
    protocol = "tcp"
    ports    = ["1194"]
  }
  source_ranges = ["${var.allowed_ip}"]
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

########### Belgium VMs (with k8s control_plane)
resource "google_compute_instance" "control_plane" {
  name         = "k8s-control-plane"
  zone         = "europe-west1-b"
  machine_type = "e2-medium"
  boot_disk {
    initialize_params {
      size  = 20
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }
  network_interface {
    network = google_compute_network.ow_network.name
    access_config {}
  }
  metadata = { ssh-keys = "${var.gc_user}:${file("../ow-gcp-key.pub")}" }
  tags     = ["private"]
}

resource "google_compute_instance" "europe_vms" {
  for_each     = var.belgium_vms
  name         = each.key
  zone         = "europe-west1-b"
  machine_type = each.value
  boot_disk {
    initialize_params {
      size  = 40
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
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
      control_ip         = google_compute_instance.control_plane.network_interface.0.access_config.0.nat_ip
      private_control_ip = google_compute_instance.control_plane.network_interface.0.network_ip
      controller_ip      = google_compute_instance.europe_vms["controller"].network_interface.0.access_config.0.nat_ip
      worker_ip          = google_compute_instance.europe_vms["worker"].network_interface.0.access_config.0.nat_ip
      private_worker_ip  = google_compute_instance.europe_vms["worker"].network_interface.0.network_ip
      edgecontroller_ip  = digitalocean_droplet.edge_controller.ipv4_address
      edgeworker_ip      = digitalocean_droplet.edge_worker.ipv4_address
      edgebroker_ip      = digitalocean_droplet.edge_broker.ipv4_address
      user               = var.gc_user
    }
  )
  filename = "../ansible/hosts.ini"
}

resource "local_file" "mycluster" {
  content = templatefile("mycluster.tmpl",
    {
      control_ip = google_compute_instance.control_plane.network_interface.0.access_config.0.nat_ip
    }
  )
  filename = "../ansible/mycluster.yaml"
}
