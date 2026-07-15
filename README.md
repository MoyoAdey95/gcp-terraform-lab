# gcp-terraform-lab

A small but realistic GCP environment built entirely with Terraform. This is a
personal lab, not client or production work. It exists so the infrastructure
patterns I use professionally (modular Terraform, least-privilege IAM, secret
injection, monitoring) are visible in a public, inspectable repo.

Built with AI-assisted tooling and deployed, tested and maintained by me.

## What it deploys

```
                        ┌─────────────────────────────────────────┐
                        │              GCP project                │
                        │                                         │
  internet ──────────►  │  Cloud Run (tf-lab-api)                 │
                        │   ├─ runtime service account (custom)   │
                        │   ├─ APP_MESSAGE env ◄── Secret Manager │
                        │   └─ direct VPC egress ──► custom VPC   │
                        │                                         │
                        │  Artifact Registry (docker images)      │
                        │  Cloud Monitoring (uptime check+alert)  │
                        └─────────────────────────────────────────┘
```

- Custom VPC + subnet + internal firewall rules (`modules/network`)
- Artifact Registry docker repository (`modules/artifact-registry`)
- Dedicated least-privilege runtime service account (`modules/iam`)
- Cloud Run v2 service with secret-backed config and direct VPC egress
  (`modules/cloud-run`)
- Uptime check + email alert policy (`modules/monitoring`)
- A tiny FastAPI container (`app/`) so there is something real to deploy

## Prerequisites

- Terraform >= 1.9
- gcloud CLI authenticated (`gcloud auth application-default login`)
- A dedicated GCP project with billing enabled (do not use a shared project)
- **Set a budget alert on the project before applying anything.**

## Bootstrap (one-time)

```bash
export PROJECT_ID=your-lab-project-id

# state bucket (name must be globally unique)
gcloud storage buckets create gs://${PROJECT_ID}-tfstate \
  --project=${PROJECT_ID} --location=EU --uniform-bucket-level-access

# then edit envs/dev/backend.tf with your bucket name
```

Required APIs are enabled by Terraform itself (see `envs/dev/main.tf`), so the
first apply may take a couple of minutes longer.

## Deploy

```bash
cd envs/dev
cp terraform.tfvars.example terraform.tfvars   # edit values
terraform init
terraform plan
terraform apply
```

The first apply uses Google's public "hello" container so the environment works
end-to-end immediately. To deploy the lab's own app:

```bash
REGION=europe-west1
REPO=$(terraform output -raw artifact_registry_url)

gcloud auth configure-docker ${REGION}-docker.pkg.dev
# --platform matters: Cloud Run runs amd64 only. Building on Apple Silicon
# without it produces an arm64 image that fails to start (exec format error).
docker build --platform linux/amd64 -t ${REPO}/tf-lab-api:0.1.0 ../../app
docker push ${REPO}/tf-lab-api:0.1.0

# set image = "<REPO>/tf-lab-api:0.1.0" in terraform.tfvars, then
terraform apply
```

Verify:

```bash
# /health, not /healthz: Google Frontend intercepts /healthz on run.app
# URLs and returns its own 404 before the request reaches the container.
curl "$(terraform output -raw service_url)/health"
curl "$(terraform output -raw service_url)/"
```

## Teardown

```bash
cd envs/dev
terraform destroy
```

The state bucket is intentionally outside Terraform; delete it manually when
you're finished with the lab entirely.

### Teardown quirks (hit in practice)

- **Subnet destroy fails with `resourceInUseByAnotherResource`:** Direct VPC
  egress reserves Google-managed `serverless-ipv4-*` addresses in the subnet,
  and they're released asynchronously after the Cloud Run service is deleted.
  You can't delete them yourself. Wait 15-20 minutes and run
  `terraform destroy` again.
- **Cloud Run refuses to delete:** provider 6.x defaults
  `deletion_protection = true`; this module sets it to false explicitly so
  the lab keeps its clean-teardown promise.

## Cost

Everything targets free tier / minimal SKUs. Destroyed between sessions it
costs effectively nothing; left running it should be pennies. Should be.

**A billing lesson this repo taught me:** the first version left
`resources.cpu_idle` at the provider default (`false`), which selects
instance-based billing: CPU is charged whenever an instance is warm, not just
while serving requests. The uptime check pinged `/health` every 5 minutes, so
one instance never went cold, and the "scales to zero" service quietly billed
around $1.50/day. A $5 budget alert caught it after three idle days. The fix
is `cpu_idle = true` (request-based billing), which suits a service doing
quick request/response work. Two takeaways I'd carry to production: monitoring
probes are traffic and can change your billing mode's behaviour, and budget
alerts are not optional.

## Security and design notes

- IAM decisions and their reasoning: [docs/iam-decisions.md](docs/iam-decisions.md)
- What I would change for production: [docs/production-deltas.md](docs/production-deltas.md)
- The service is deliberately public (`allUsers` invoker) in this lab. Securing
  ingress properly (load balancer, serverless NEG, Cloud Armor, blocked default
  URL) is a separate project: **gcp-secure-ingress**.

## Repo layout

```
app/                    # FastAPI demo container
modules/                # reusable terraform modules
  network/
  artifact-registry/
  iam/
  cloud-run/
  monitoring/
envs/dev/               # composition root for the dev environment
docs/                   # design decisions & evidence
.github/workflows/      # fmt/validate CI
```
