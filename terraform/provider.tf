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

variable "belgium_names" {
  default = ["controller1", "worker1", "worker2"]
}
variable "oregon_names" {
  default = ["controller2", "worker3"]
}
variable "toronto_names" {
  default = ["controller3", "worker4"]
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
  #   target_tags = ["k8s-control-plane", "controller1", "controller2", "controller3", "worker1", "worker2", "worker3", "worker4"]
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
  # source_tags = ["k8s-control-plane", "controller1", "controller2", "controller3", "worker1", "worker2", "worker3", "worker4"]
  # source_ranges = [""]
}

########### Belgium VMs (with k8s control_plane)
resource "google_compute_instance" "control_plane" {
  name         = "k8s-control-plane"
  machine_type = "e2-medium"
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }
  network_interface {
    network = google_compute_network.ow_network.name
    access_config {}
  }
  metadata = { ssh-keys = "${var.gc_user}:${file("../ow-gcp-key.pub")}" }
  tags = ["private"]
}

resource "google_compute_instance" "europe_vms" {
  for_each     = toset(var.belgium_names)
  name         = each.value
  zone         = "europe-west1-b"
  machine_type = "e2-small"
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }
  network_interface {
    network = google_compute_network.ow_network.name
    access_config {}
  }
  metadata = { ssh-keys = "${var.gc_user}:${file("../ow-gcp-key.pub")}" }
  tags = ["private"]
}


############ Oregon VMs
resource "google_compute_instance" "us_east_vms" {
  for_each     = toset(var.oregon_names)
  name         = each.value
  zone         = "us-east1-c"
  machine_type = "e2-small"
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }
  network_interface {
    network = google_compute_network.ow_network.name
    access_config {}
  }
  metadata = { ssh-keys = "${var.gc_user}:${file("../ow-gcp-key.pub")}" }
  tags = ["private"]
}

############ Toronto VMs
resource "google_compute_instance" "toronto_vms" {
  for_each     = toset(var.toronto_names)
  name         = each.value
  zone         = "northamerica-northeast2-a"
  machine_type = "e2-small"
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }
  network_interface {
    network = google_compute_network.ow_network.name
    access_config {}
  }
  metadata = { ssh-keys = "${var.gc_user}:${file("../ow-gcp-key.pub")}" }
  tags = ["private"]
}

resource "local_file" "hosts" {
  content = templatefile("hosts.tmpl",
    {
      control_ip = google_compute_instance.control_plane.network_interface.0.access_config.0.nat_ip
      worker1_ip = google_compute_instance.europe_vms["controller1"].network_interface.0.access_config.0.nat_ip
      worker2_ip = google_compute_instance.europe_vms["worker1"].network_interface.0.access_config.0.nat_ip
      worker3_ip = google_compute_instance.europe_vms["worker2"].network_interface.0.access_config.0.nat_ip
      worker4_ip = google_compute_instance.us_east_vms["controller2"].network_interface.0.access_config.0.nat_ip
      worker5_ip = google_compute_instance.us_east_vms["worker3"].network_interface.0.access_config.0.nat_ip
      worker6_ip = google_compute_instance.toronto_vms["controller3"].network_interface.0.access_config.0.nat_ip
      worker7_ip = google_compute_instance.toronto_vms["worker4"].network_interface.0.access_config.0.nat_ip
      user       = var.gc_user
    }
  )
  filename = "../ansible/hosts.ini"
}
