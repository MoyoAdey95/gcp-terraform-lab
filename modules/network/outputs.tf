output "network_id" {
  description = "Self link / ID of the VPC"
  value       = google_compute_network.vpc.id
}

output "network_name" {
  description = "Name of the VPC"
  value       = google_compute_network.vpc.name
}

output "subnet_id" {
  description = "Self link / ID of the main subnet"
  value       = google_compute_subnetwork.main.id
}
