resource "google_cloud_run_v2_service" "service" {
  name     = "${var.name_prefix}-api"
  location = var.region

  # Provider 6.x defaults this to true, which blocks `terraform destroy`.
  # A lab that promises clean teardown must be destroyable.
  deletion_protection = false

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
        # Request-based billing. The provider default (cpu_idle = false) means
        # instance-based billing: CPU is charged for as long as an instance is
        # warm. With the uptime check hitting /health every 5 minutes, one
        # instance never went cold and idled at roughly $1.50/day. Found via a
        # budget alert, not the docs. See "Cost" in the README.
        cpu_idle = true
      }
    }

    # Direct VPC egress. Outbound traffic to private ranges goes through the
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

# Lab-only. The service is publicly invokable so it can be curl'd and uptime-
# checked without auth. Gated behind a variable so it's an explicit choice.
resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  count = var.allow_public_access ? 1 : 0

  name     = google_cloud_run_v2_service.service.name
  location = var.region
  role     = "roles/run.invoker"
  member   = "allUsers"
}
