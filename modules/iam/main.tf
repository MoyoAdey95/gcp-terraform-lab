# Dedicated runtime identity for the Cloud Run service.
#
# The alternative is the default compute service account, which historically
# carries the project Editor role, which is far too broad. This SA starts with
# zero permissions; anything it needs is granted explicitly, as close to the
# resource as possible (see the secret IAM binding in envs/dev/main.tf).

resource "google_service_account" "cloud_run_runtime" {
  account_id   = "${var.name_prefix}-run-sa"
  display_name = "Cloud Run runtime for ${var.name_prefix}"
  description  = "Least-privilege runtime identity; permissions granted per-resource"
}
