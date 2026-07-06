variable "name_prefix" {
  description = "Prefix for all network resource names"
  type        = string
}

variable "region" {
  description = "Region for the subnet"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR range for the main subnet"
  type        = string
  default     = "10.10.0.0/24"
}
