# Architecture

GEOS runs on a 3-tier AWS architecture, fully provisioned through idempotent
Bash scripts against a single `config.yaml` source of truth. This document
describes the shape of the system; see [decisions.md](decisions.md) for the
reasoning behind specific choices.

## High-level request flow

```
User Browser
    |
    | HTTPS (443)
    v
Route 53 / DNS  --(CNAME)-->  Application Load Balancer (public subnets)
                                    |
                          TLS terminated here (ACM certificate)
                                    |
                          HTTP (plain, internal VPC traffic)
                                    |
                    -----------------------------------
                    |                                 |
              App Server 1                       App Server 2
           (private subnet, AZ-a)              (private subnet, AZ-b)
                    |                                 |
                 Nginx (reverse proxy)          Nginx (reverse proxy)
                    |                                 |
           /        \                        /        \
     static React    /api/ -> Go backend    static React /api/ -> Go backend
     (geos-frontend)  (localhost:8000)       (geos-frontend) (localhost:8000)
                    \                                 /
                     \                               /
                      -----------------------------
                                    |
                          RDS PostgreSQL (isolated
                          private DB subnets, no
                          internet route at all)
```

## VPC layout

A single VPC, split into three tiers across two Availability Zones:

| Tier | Subnets | Route table | Internet access |
|---|---|---|---|
| Public | 2 (one per AZ) | Main route table, `0.0.0.0/0 -> IGW` | Full |
| Private (app) | 2 (one per AZ) | Dedicated route table, `0.0.0.0/0 -> NAT Gateway` | Outbound only, via NAT |
| Private (DB, isolated) | 2 (one per AZ) | Dedicated route table, local traffic only | None |

The isolated DB tier has no route to the internet in either direction — RDS
never needs to initiate outbound traffic, so no NAT route was added for it.

## Compute

- **Application Load Balancer** — internet-facing, spans both public subnets.
  One Target Group, HTTP and HTTPS Listeners.
- **App-tier EC2 instances (x2)** — one per AZ, private subnets, registered
  behind the ALB. Each runs Nginx (reverse proxy + static file server) and
  the Go backend as a systemd service.
- **Bastion host** — single EC2 instance in a public subnet, the only SSH
  entry point into the private tiers. Security Group restricted to a single
  known IP for interactive access.

## Database

- **RDS PostgreSQL**, single instance, in the isolated DB subnets.
- Master credentials generated and managed entirely by AWS
  (`--manage-master-user-password`), stored in **Secrets Manager**.
  No password is ever set, seen, or stored manually.
- Not publicly accessible. Security Group allows inbound traffic on 5432
  from the app-tier Security Group only — nothing else, not even the
  bastion.

## Secrets & permissions (IAM chain)

```
IAM Role (geos-db-secrets-role)
  |-- Trust Policy: only ec2.amazonaws.com may assume this role
  |-- Permissions Policy: secretsmanager:GetSecretValue,
  |                        scoped to exactly one secret ARN (the RDS secret)
  |
  v
Instance Profile (geos-db-secrets-profile)
  |-- wraps the Role (EC2-specific requirement -- EC2 cannot hold a
  |   Role directly, unlike other AWS compute services)
  |
  v
Attached to both app-tier EC2 instances at launch time
```

At runtime, the Go backend's AWS SDK client requests credentials from the
instance's metadata service (IMDS). IMDS returns temporary credentials tied
to the attached Role. The SDK uses those credentials to call
`secretsmanager:GetSecretValue`, AWS checks the Role's permissions policy,
and — if permitted — returns the database password. The password is never
stored in a config file, environment variable file, or committed anywhere;
it exists only in memory for the life of the process that fetched it.

## Provisioning

Everything above (VPC, subnets, route tables, NAT Gateway, ALB, Target
Group, RDS, IAM chain, EC2 instances, Security Groups) is created by two
scripts:

- `provision_infra.sh` — VPC through the IAM chain and RDS
- `provision_resources.sh` — bastion and app-tier EC2 instances, Target
  Group registration

Both read from and write resource IDs back into `config/config.yaml`,
making the whole chain reproducible from a clean AWS account.

### Instance bootstrapping (user-data)

Every app-tier EC2 instance is fully self-sufficient from the moment it
boots, with no manual steps required. User-data:

1. Installs Nginx, the AWS CLI, `jq`, and `postgresql-client`
2. Creates the working directories for the backend and frontend
3. Writes the systemd service definition for the Go backend
4. Writes the Nginx reverse-proxy configuration
5. Writes `prodConfig.yaml`, with the real Secrets Manager ARN and RDS
   endpoint substituted in via `sed` before the instance ever launches
   (the checked-in template uses `__SECRET_ARN__` / `__RDS_ENDPOINT__`
   placeholders)
6. Fetches the DB secret via the IAM chain above and creates the
   application database if it doesn't already exist
7. Enables and starts Nginx (the backend service is *enabled*, not
   started — it has no binary yet until the first deploy)

## CI/CD

Two separate GitHub Actions pipelines, one per repository:

**Backend** (on push to `master`):
1. Build the Go binary
2. Upload it as an artifact
3. A second job downloads the artifact and, through the bastion, for each
   app-tier instance: stops the service, copies the new binary, sets
   execute permissions, restarts the service

**Frontend** (on push to `master`):
1. `npm run build` (Vite), with `VITE_BACKEND_URL` set at build time
2. Upload the `dist/` output as an artifact
3. A second job copies the built files through the bastion to each
   app-tier instance's frontend directory — no restart needed, since
   Nginx just serves whatever files are on disk

## TLS / HTTPS

- Certificate issued by AWS Certificate Manager for the production domain,
  DNS-validated.
- Attached to the ALB's HTTPS (443) Listener. TLS is terminated centrally
  at the ALB; traffic between the ALB and app-tier instances travels as
  plain HTTP inside the private VPC.
- The HTTP (80) Listener redirects all traffic to HTTPS.

## Cutover

The previous production domain now issues a permanent HTTP 301 redirect
(configured directly in that server's Nginx config) to the new domain,
preserving any existing bookmarks and search engine indexing.

## Observability

Three CloudWatch alarms, all notifying a single SNS topic (email
subscription):

- **ALB unhealthy host count** — fires if any app-tier instance fails its
  ALB health check
- **RDS CPU utilization** — fires on sustained high CPU (5-minute average
  above threshold)
- **EC2 status check failure** — fires on infrastructure/OS-level failure
  of either app-tier instance, independent of application health

## What's provisioned outside the scripts

ACM certificate request/validation, the ALB's HTTPS Listener, the old-domain
redirect, and the CloudWatch alarms/SNS topic were set up manually (via CLI
or console) rather than folded into the provisioning scripts. These are
one-time or rarely-changing pieces where the effort of scripting didn't
outweigh the benefit, unlike the core infrastructure, which was rebuilt
many times during development and testing.   
