# What would change for production

This lab optimises for inspectability and near-zero cost. A production version
of the same stack would differ in at least these ways:

**State and collaboration.** State bucket with versioning + a locking story,
separate state per environment, and plans applied only from CI, never from a
laptop. CI would authenticate via Workload Identity Federation instead of any
form of key file.

**Environments.** A `envs/staging` and `envs/prod` alongside `envs/dev`,
identical module versions promoted through them, with per-env tfvars. Module
sources would be pinned to tagged releases, not relative paths, once shared
across teams.

**Ingress.** No `allUsers` invoker and no direct `run.app` exposure: external
HTTPS load balancer, serverless NEG, Cloud Armor policy, custom domain with
managed certs, and Cloud Run ingress restricted to
`internal-and-cloud-load-balancing`. (Implemented in the companion
`gcp-secure-ingress` project.)

**Reliability.** `min_instance_count` >= 1 for latency-sensitive services,
multi-region behind a global LB where justified, and real SLOs with
burn-rate alerting instead of a single uptime check.

**Secrets and config.** Pinned secret versions (not `latest`) so a bad secret
rollout is a deliberate deploy, rotation policy, and separation between
app-owned and platform-owned secrets.

**Observability.** Structured JSON logging in the app, log-based error-rate
metrics and 5xx/latency alerting alongside the uptime check, and a dashboard
per service.

**Cost/scale guards.** The `max_instances = 2` cost guard becomes a
capacity-planned number; budgets and quota alerts managed in Terraform too.
