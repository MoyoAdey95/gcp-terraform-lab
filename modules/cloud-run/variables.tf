variable "name_prefix" {
  description = "Prefix for the service name"
  type        = string
}

variable "region" {
  description = "Region for the Cloud Run service"
  type        = string
}

variable "image" {
  description = "Full container image URL to deploy"
  type        = string
}

variable "service_account_email" {
  description = "Runtime service account email"
  type        = string
}

variable "secret_id" {
  description = "Secret Manager secret ID injected as APP_MESSAGE"
  type        = string
}

variable "network_id" {
  description = "VPC for direct VPC egress"
  type        = string
}

variable "subnet_id" {
  description = "Subnet for direct VPC egress"
  type        = string
}

variable "max_instances" {
  description = "Upper scaling bound (cost guard)"
  type        = number
  default     = 2
}

variable "allow_public_access" {
  description = "Grant allUsers run.invoker (lab convenience)"
  type        = bool
  default     = true
}
