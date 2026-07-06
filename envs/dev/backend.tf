# Remote state in GCS. The bucket is created once, outside Terraform, during
# bootstrap (see README) — state storage shouldn't depend on the state it holds.
#
terraform {
  backend "gcs" {
    bucket = "moyo-cloud-lab-tfstate"
    prefix = "gcp-terraform-lab/dev"
  }
}
