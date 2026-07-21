# IAM decisions

## Custom runtime service account instead of the default compute SA

Cloud Run services run as the default compute service account unless told
otherwise, and that account historically carries project Editor, meaning a
compromised container could touch almost anything in the project. The lab
creates a dedicated SA with zero initial permissions (`modules/iam`).

## Resource-level secret access instead of a project-level role

The runtime SA is granted `roles/secretmanager.secretAccessor` **on the one
secret it needs** (`envs/dev/main.tf`), not at project level. Project-level
secretAccessor would silently expose every future secret in the project to
this service. Resource-level grants keep the blast radius to exactly one
secret.

## No logging/monitoring grants on the runtime SA

Container stdout/stderr is captured by Cloud Run's own service agent, so the
runtime SA needs no logging role. This gets asked about a lot. Granting
`roles/logging.logWriter` "just in case" is a common bit of cargo-culting.

## allUsers invoker, a deliberate, gated exception

Public invocation is a lab convenience (so the service can be curl'd and
uptime-checked without auth tokens), gated behind `allow_public_access` so it
is an explicit choice visible in the plan. In production this would be
removed and ingress locked to an HTTPS load balancer. That pattern is the
subject of the companion `gcp-secure-ingress` project.

## Who applies the Terraform?

In this lab, my user credentials via ADC. In production, a dedicated deployer
SA used by CI, authenticated with Workload Identity Federation (no exported
JSON keys), with roles scoped to what the stack manages. See
[production-deltas.md](production-deltas.md).
