output "service_url" {
  description = "Public URL of the deployed service"
  value       = module.cloud_run.service_url
}

output "artifact_registry_url" {
  description = "Push/pull URL for container images"
  value       = module.artifact_registry.repository_url
}

output "runtime_service_account" {
  description = "Email of the Cloud Run runtime SA"
  value       = module.iam.runtime_service_account_email
}

output "network_name" {
  description = "Name of the lab VPC"
  value       = module.network.network_name
}
