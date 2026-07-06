# Composition root for the dev environment. Modules do the work; this file
# wires them together and owns the few things too small to modularise
# (API enablement, the demo secret).

locals {
  required_apis = [
    "run.googleapis.com",
    "compute.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "monitoring.googleapis.com",
    "iam.googleapis.com",
  ]
}

resource "google_project_service" "required" {
  for_each = toset(local.required_apis)

  service            = each.value
  disable_on_destroy = false
}

module "network" {
  source = "../../modules/network"

  name_prefix = var.name_prefix
  region      = var.region
  subnet_cidr = var.subnet_cidr

  depends_on = [google_project_service.required]
}

module "artifact_registry" {
  source = "../../modules/artifact-registry"

  project_id    = var.project_id
  region        = var.region
  repository_id = "${var.name_prefix}-images"

  depends_on = [google_project_service.required]
}

module "iam" {
  source = "../../modules/iam"

  name_prefix = var.name_prefix

  depends_on = [google_project_service.required]
}

# The demo secret lives here rather than in a module: it's a single resource
# with no reuse story, and a "secrets module" wrapping one secret would be
# structure for structure's sake.
resource "google_secret_manager_secret" "app_message" {
  secret_id = "${var.name_prefix}-app-message"

  replication {
    auto {}
  }

  depends_on = [google_project_service.required]
}

resource "google_secret_manager_secret_version" "app_message" {
  secret      = google_secret_manager_secret.app_message.id
  secret_data = var.app_message
}

# Resource-level grant: the runtime SA can read this one secret, not all
# secrets in the project (which is what roles/secretmanager.secretAccessor at
# project level would give).
resource "google_secret_manager_secret_iam_member" "runtime_accessor" {
  secret_id = google_secret_manager_secret.app_message.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.iam.runtime_service_account_email}"
}

module "cloud_run" {
  source = "../../modules/cloud-run"

  name_prefix           = var.name_prefix
  region                = var.region
  image                 = var.image
  service_account_email = module.iam.runtime_service_account_email
  secret_id             = google_secret_manager_secret.app_message.secret_id
  network_id            = module.network.network_id
  subnet_id             = module.network.subnet_id
  max_instances         = var.max_instances
  allow_public_access   = true

  depends_on = [google_secret_manager_secret_iam_member.runtime_accessor]
}

module "monitoring" {
  source = "../../modules/monitoring"

  name_prefix  = var.name_prefix
  project_id   = var.project_id
  service_host = replace(module.cloud_run.service_url, "https://", "")
  alert_email  = var.alert_email
}
