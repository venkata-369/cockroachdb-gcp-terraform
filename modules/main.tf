# ------------------------------------------------------------
# VPC
# ------------------------------------------------------------

resource "google_compute_network" "cockroach_vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# ------------------------------------------------------------
# Subnets (one per node)
# ------------------------------------------------------------

resource "google_compute_subnetwork" "subnet_1" {
  name          = "cockroach-subnet-1"
  ip_cidr_range = var.subnet_1_cidr
  region        = var.region
  network       = google_compute_network.cockroach_vpc.id
}

resource "google_compute_subnetwork" "subnet_2" {
  name          = "cockroach-subnet-2"
  ip_cidr_range = var.subnet_2_cidr
  region        = var.region
  network       = google_compute_network.cockroach_vpc.id
}

resource "google_compute_subnetwork" "subnet_3" {
  name          = "cockroach-subnet-3"
  ip_cidr_range = var.subnet_3_cidr
  region        = var.region
  network       = google_compute_network.cockroach_vpc.id
}

# ------------------------------------------------------------
# Firewall - SSH  (restrict via var.ssh_source_ranges)
# ------------------------------------------------------------

resource "google_compute_firewall" "allow_ssh" {
  name      = "cockroach-allow-ssh"
  network   = google_compute_network.cockroach_vpc.name
  direction = "INGRESS"

  source_ranges = var.ssh_source_ranges

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = ["cockroachdb"]
}

# ------------------------------------------------------------
# Firewall - CockroachDB SQL / inter-node RPC (26257)
# Only from inside the VPC (the three node subnets).
# Verified port: https://www.cockroachlabs.com/docs/stable/deploy-cockroachdb-on-premises
# ------------------------------------------------------------

resource "google_compute_firewall" "allow_cockroach" {
  name      = "cockroach-allow-internal"
  network   = google_compute_network.cockroach_vpc.name
  direction = "INGRESS"

  source_ranges = [
    var.subnet_1_cidr,
    var.subnet_2_cidr,
    var.subnet_3_cidr,
  ]

  allow {
    protocol = "tcp"
    ports    = ["26257"]
  }

  target_tags = ["cockroachdb"]
}

# ------------------------------------------------------------
# Firewall - DB Console (8080)  restricted to var.db_console_source_ranges
# ------------------------------------------------------------

resource "google_compute_firewall" "allow_db_console" {
  name      = "cockroach-allow-8080"
  network   = google_compute_network.cockroach_vpc.name
  direction = "INGRESS"

  source_ranges = var.db_console_source_ranges

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  target_tags = ["cockroachdb"]
}

# ------------------------------------------------------------
# Firewall - ICMP (internal only, for ping/troubleshooting)
# ------------------------------------------------------------

resource "google_compute_firewall" "allow_icmp" {
  name      = "cockroach-allow-icmp"
  network   = google_compute_network.cockroach_vpc.name
  direction = "INGRESS"

  source_ranges = [
    var.subnet_1_cidr,
    var.subnet_2_cidr,
    var.subnet_3_cidr,
  ]

  allow {
    protocol = "icmp"
  }

  target_tags = ["cockroachdb"]
}

# ------------------------------------------------------------
# 3 CockroachDB nodes (via module)
# ------------------------------------------------------------

locals {
  nodes = {
    "cockroach-1" = google_compute_subnetwork.subnet_1.id
    "cockroach-2" = google_compute_subnetwork.subnet_2.id
    "cockroach-3" = google_compute_subnetwork.subnet_3.id
  }
}

module "cockroach_node" {
  source   = "./modules/cockroach-node"
  for_each = local.nodes

  name          = each.key
  subnetwork_id = each.value
  zone          = var.zone
  machine_type  = var.machine_type
  crdb_version  = var.crdb_version
}
