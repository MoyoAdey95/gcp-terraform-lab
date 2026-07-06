resource "google_artifact_registry_repository" "docker" {
  repository_id = var.repository_id
  location      = var.region
  format        = "DOCKER"
  description   = "Container images for gcp-terraform-lab"
}
