# Custom VPC for the lab. auto_create_subnetworks is disabled deliberately:
# the default-mode VPC creates a subnet in every region, which is both wasteful
# and hides the networking decisions this lab is meant to demonstrate.

resource "google_compute_network" "vpc" {
  name                    = "${var.name_prefix}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "main" {
  name                     = "${var.name_prefix}-subnet"
  ip_cidr_range            = var.subnet_cidr
  region                   = var.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true
}

# Internal-only traffic between resources in the subnet. There is deliberately
# no 0.0.0.0/0 ingress rule: nothing in this VPC accepts traffic from the
# internet directly (Cloud Run ingress is handled by Google's frontend).
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.name_prefix}-allow-internal"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.subnet_cidr]
}
