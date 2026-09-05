# ------------------------------------------------------------
# VPC
# ------------------------------------------------------------

resource "google_compute_network" "cockroach_vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# ------------------------------------------------------------
# Subnet 1
# ------------------------------------------------------------

resource "google_compute_subnetwork" "subnet_1" {
  name          = "cockroach-subnet-1"
  ip_cidr_range = var.subnet_1_cidr
  region        = var.region
  network       = google_compute_network.cockroach_vpc.id
}

# ------------------------------------------------------------
# Subnet 2
# ------------------------------------------------------------

resource "google_compute_subnetwork" "subnet_2" {
  name          = "cockroach-subnet-2"
  ip_cidr_range = var.subnet_2_cidr
  region        = var.region
  network       = google_compute_network.cockroach_vpc.id
}

# ------------------------------------------------------------
# Subnet 3
# ------------------------------------------------------------

resource "google_compute_subnetwork" "subnet_3" {
  name          = "cockroach-subnet-3"
  ip_cidr_range = var.subnet_3_cidr
  region        = var.region
  network       = google_compute_network.cockroach_vpc.id
}

# ------------------------------------------------------------
# Firewall - SSH
# ------------------------------------------------------------

resource "google_compute_firewall" "allow_ssh" {
  name    = "cockroach-allow-ssh"
  network = google_compute_network.cockroach_vpc.name

  direction = "INGRESS"

  source_ranges = var.ssh_source_ranges

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = ["cockroachdb"]
}

# ------------------------------------------------------------
# Firewall - CockroachDB and requested ports
# ------------------------------------------------------------

resource "google_compute_firewall" "allow_cockroach" {
  name    = "cockroach-allow-internal"
  network = google_compute_network.cockroach_vpc.name

  direction = "INGRESS"

  source_ranges = [
    var.subnet_1_cidr,
    var.subnet_2_cidr,
    var.subnet_3_cidr
  ]

  allow {
    protocol = "tcp"
    ports = [
      "25267",
      "26257"
    ]
  }

  target_tags = ["cockroachdb"]
}

# ------------------------------------------------------------
# Firewall - Port 8080
# ------------------------------------------------------------

resource "google_compute_firewall" "allow_8080" {
  name    = "cockroach-allow-8080"
  network = google_compute_network.cockroach_vpc.name

  direction = "INGRESS"

  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  target_tags = ["cockroachdb"]
}

# ------------------------------------------------------------
# Firewall - ICMP
# ------------------------------------------------------------

resource "google_compute_firewall" "allow_icmp" {
  name    = "cockroach-allow-icmp"
  network = google_compute_network.cockroach_vpc.name

  direction = "INGRESS"

  source_ranges = [
    var.subnet_1_cidr,
    var.subnet_2_cidr,
    var.subnet_3_cidr
  ]

  allow {
    protocol = "icmp"
  }

  target_tags = ["cockroachdb"]
}

# ------------------------------------------------------------
# VM 1
# ------------------------------------------------------------

resource "google_compute_instance" "cockroach_1" {
  name         = "cockroach-1"
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["cockroachdb"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 30
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_1.id

    access_config {
      # Ephemeral public IP
    }
  }

  metadata = {
    enable-oslogin = "TRUE"
  }
}

# ------------------------------------------------------------
# VM 2
# ------------------------------------------------------------

resource "google_compute_instance" "cockroach_2" {
  name         = "cockroach-2"
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["cockroachdb"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 30
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_2.id

    access_config {
      # Ephemeral public IP
    }
  }

  metadata = {
    enable-oslogin = "TRUE"
  }
}

# ------------------------------------------------------------
# VM 3
# ------------------------------------------------------------

resource "google_compute_instance" "cockroach_3" {
  name         = "cockroach-3"
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["cockroachdb"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 30
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_3.id

    access_config {
      # Ephemeral public IP
    }
  }

  metadata = {
    enable-oslogin = "TRUE"
  }
}
