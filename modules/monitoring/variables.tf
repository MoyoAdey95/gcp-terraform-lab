variable "name_prefix" {
  description = "Prefix for monitoring resource names"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "service_host" {
  description = "Hostname of the service to uptime-check (no scheme)"
  type        = string
}

variable "alert_email" {
  description = "Email for alert notifications; empty string disables the channel"
  type        = string
  default     = ""
}
