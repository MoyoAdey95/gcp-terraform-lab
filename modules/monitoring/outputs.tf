output "uptime_check_id" {
  description = "ID of the uptime check"
  value       = google_monitoring_uptime_check_config.service.uptime_check_id
}

output "alert_policy_name" {
  description = "Name of the uptime alert policy"
  value       = google_monitoring_alert_policy.uptime_failure.name
}
