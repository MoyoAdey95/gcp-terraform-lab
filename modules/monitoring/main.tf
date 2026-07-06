# Uptime check against the public /health endpoint, plus an alert policy
# that fires if the check fails. Email channel is optional so the module can
# be applied without committing a personal address to tfvars in a hurry.

resource "google_monitoring_uptime_check_config" "service" {
  display_name = "${var.name_prefix}-uptime"
  timeout      = "10s"
  period       = "300s"

  http_check {
    path         = "/health"
    port         = 443
    use_ssl      = true
    validate_ssl = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = var.service_host
    }
  }
}

resource "google_monitoring_notification_channel" "email" {
  count = var.alert_email != "" ? 1 : 0

  display_name = "${var.name_prefix}-email"
  type         = "email"

  labels = {
    email_address = var.alert_email
  }
}

resource "google_monitoring_alert_policy" "uptime_failure" {
  display_name = "${var.name_prefix} uptime check failing"
  combiner     = "OR"

  conditions {
    display_name = "Uptime check failures"

    condition_threshold {
      filter          = "resource.type = \"uptime_url\" AND metric.type = \"monitoring.googleapis.com/uptime_check/check_passed\" AND metric.labels.check_id = \"${google_monitoring_uptime_check_config.service.uptime_check_id}\""
      comparison      = "COMPARISON_GT"
      threshold_value = 1
      duration        = "300s"

      aggregations {
        alignment_period     = "1200s"
        per_series_aligner   = "ALIGN_NEXT_OLDER"
        cross_series_reducer = "REDUCE_COUNT_FALSE"
        group_by_fields      = ["resource.label.*"]
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = google_monitoring_notification_channel.email[*].name

  documentation {
    content = "The ${var.name_prefix} uptime check is failing. Check Cloud Run service status, recent deployments, and error logs."
  }
}
