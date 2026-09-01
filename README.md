# GEOS Infrastructure

Infrastructure-as-scripts and CI/CD pipeline for GEOS, a live four-portal
SaaS EdTech platform (SysAdmin, School, Student, University), redesigned
from the ground up on AWS.

## Why this exists

GEOS has been running in production, serving a real school, on a manually
configured server. This repo rebuilds its infrastructure from scratch with
proper isolation, automation, and observability — without any downtime to
the live system.

## Architecture

- 3-tier VPC: public subnet (ALB only) → private subnet (app servers) →
  private subnet (PostgreSQL DB)
- Single React build (route-based portal separation), single Go backend,
  one ALB + one Target Group
- Nginx as reverse proxy on each app instance
- AWS Secrets Manager for DB credentials and API keys
- Full CI/CD via GitHub Actions: lint/build on push, deploy on merge to `master`
- Provisioning via idempotent bash scripts (AWS CLI) — no manual console setup

See [docs/architecture.md](docs/architecture.md) for the full diagram and
[docs/decisions.md](docs/decisions.md) for the reasoning behind key choices.

## Status

🚧 Built Completed.

## Cutover plan

The existing production system stays untouched throughout. Once this
architecture is fully tested, a redirect page will be added within the
current app pointing users to the new domain — zero downtime, no DNS risk.
