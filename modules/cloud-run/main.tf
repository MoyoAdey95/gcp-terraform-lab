resource "google_cloud_run_v2_service" "service" {
  name     = "${var.name_prefix}-api"
  location = var.region

  # Public ingress is a deliberate lab simplification. Hardened ingress
  # (LB + serverless NEG + Cloud Armor + blocked default URL) is covered by
  # the separate gcp-secure-ingress project.
  ingress = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = var.service_account_email

    scaling {
      min_instance_count = 0
      max_instance_count = var.max_instances
    }

    containers {
      image = var.image

      ports {
        container_port = 8080
      }

      env {
        name = "APP_MESSAGE"
        value_source {
          secret_key_ref {
            secret  = var.secret_id
            version = "latest"
          }
        }
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }

    # Direct VPC egress: outbound traffic to private ranges goes through the
    # lab VPC, so the network module is doing real work rather than being
    # decorative. Internet-bound traffic still egresses directly.
    vpc_access {
      network_interfaces {
        network    = var.network_id
        subnetwork = var.subnet_id
      }
      egress = "PRIVATE_RANGES_ONLY"
    }
  }
}

# Lab-only: the service is publicly invokable so it can be curl'd and uptime-
# checked without auth. Gated behind a variable so it's an explicit choice.
resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  count = var.allow_public_access ? 1 : 0

  name     = google_cloud_run_v2_service.service.name
  location = var.region
  role     = "roles/run.invoker"
  member   = "allUsers"
}
