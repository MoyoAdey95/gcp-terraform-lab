variable "project_id" {
  description = "GCP project ID for the lab"
  type        = string
}

variable "region" {
  description = "Primary region"
  type        = string
  default     = "europe-west1"
}

variable "name_prefix" {
  description = "Short prefix for resource names (lowercase, hyphens)"
  type        = string
  default     = "tf-lab"
}

variable "subnet_cidr" {
  description = "CIDR for the main subnet"
  type        = string
  default     = "10.10.0.0/24"
}

variable "image" {
  description = "Container image to deploy. Default is Google's public hello image so the first apply works before you've pushed anything."
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "app_message" {
  description = "Value stored in Secret Manager and injected as APP_MESSAGE. Set a real value in terraform.tfvars (which is gitignored)."
  type        = string
  sensitive   = true
  default     = "hello from secret manager"
}

variable "max_instances" {
  description = "Cloud Run max instances (cost guard)"
  type        = number
  default     = 2
}

variable "alert_email" {
  description = "Email for uptime alerts; leave empty to skip the notification channel"
  type        = string
  default     = ""
}
