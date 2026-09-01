# Decisions

This document captures the reasoning behind choices made during the GEOS
infrastructure redesign — the "why," not just the "what." See
[architecture.md](architecture.md) for the system's actual shape.

## Why rebuild instead of patch the existing setup?

The original GEOS deployment was a single, manually configured EC2 instance
running the app, Nginx, and connecting to a single RDS instance directly.
It worked, and it's still serving a real school's traffic. But it had no
redundancy (one instance failing takes the whole app down), no isolation
between tiers, credentials sitting in a local YAML file, and every change
was a manual SSH session. The goal of this project was to rebuild that into
something that reflects real production practice, without touching the live
system until the new one was fully proven.

## Why a 3-tier VPC instead of the original flat setup?

Separating public, private-app, and private-DB subnets means a compromise
of any single layer doesn't automatically expose the others. The database
specifically can never be reached from the internet, under any
circumstance, regardless of what Security Group rules exist — the network
topology itself makes it unreachable, which is a stronger guarantee than a
Security Group rule alone (rules can be misconfigured; a missing route
cannot be worked around by a rule mistake).

## Why does the DB subnet tier have no NAT Gateway route?

RDS only ever needs to be reached *by* the app tier — it never needs to
reach *out* to the internet itself. Giving it a NAT route would grant a
capability it has no legitimate use for, purely as an unnecessary exposure.
This mirrors the general principle applied everywhere in this build:
grant only the access something actually needs, nothing more.

## Why `--manage-master-user-password` instead of setting the RDS password manually?

A manually set password has to be typed somewhere, stored somewhere, and
remembered by someone — every one of those is a point where it could leak.
Letting RDS generate and manage the password directly in Secrets Manager
removes the human from that loop entirely, and comes with automatic
rotation (every 7 days, by default) at no extra effort.

## Why IAM Role + Instance Profile instead of storing AWS access keys on the instance?

A stored access key is a long-lived, static secret sitting on disk — if the
instance is ever compromised, that key is compromised indefinitely until
someone notices and rotates it. An IAM Role attached via an Instance
Profile issues only short-lived, automatically-rotated temporary
credentials through the instance metadata service. Nothing sensitive is
ever written to disk, and the permissions are scoped to exactly one action
(`secretsmanager:GetSecretValue`) on exactly one resource (the specific
secret's ARN) — not broad account access.

## Why terminate TLS at the ALB instead of on each instance (Certbot per-instance)?

The previous setup used Certbot directly on the single EC2 instance, which
means every additional instance would need its own certificate and its own
renewal cycle to manage. Terminating TLS once, centrally, at the ALB means
certificate management (issuance, renewal) happens in exactly one place via
ACM, and it doesn't matter how many app-tier instances exist behind
it — none of them need to know or care about certificates at all. Traffic
between the ALB and the instances stays as plain HTTP, which is acceptable
because it never leaves the private VPC.

## Why build the binary in GitHub Actions rather than on the instance?

Building on a live, traffic-serving instance means using its CPU and memory
for something other than serving requests, and a broken build could leave
the instance in a half-updated state. Building in an isolated CI runner
keeps builds reproducible and keeps the instances themselves lightweight —
they only ever need to run a finished, already-tested artifact, not compile
one.

## Why stop the service before overwriting the binary, rather than copying over a running process?

Overwriting a binary file while the OS still has it open for execution can
fail or leave things in an inconsistent state. Stopping the service first,
replacing the file, then starting it again is the standard, reliable
pattern for this kind of deploy — a brief moment of downtime on a single
instance during deploy, which is acceptable since the second instance stays
up throughout (rolling deploys instance-by-instance were not implemented in
this version, but the stop/copy/start pattern is what such a future rolling
deploy would build on).

## Why user-data instead of manually configuring each new instance?

Manually repeating the same setup steps (install Nginx, write config files,
create the systemd service, create the database) on every new instance is
slow and error-prone, and it was in fact where several real bugs were
found and fixed during development (a missing execute permission, a
database that didn't yet exist, a stale variable read before its value
existed). Baking all of this into user-data means every future instance
comes up in an identical, correct, self-sufficient state with zero manual
steps — the same guarantee IaC gives for the infrastructure itself, applied
to the instance's own internal setup.

## Why is the cutover a server-side 301 redirect rather than an in-app page?

An in-app redirect page still requires the old application to load and
render before sending the user onward, and it doesn't communicate anything
to search engines or other automated clients. A 301 issued directly by
Nginx, before the request ever reaches the application, is faster, works
for every path (not just the homepage) via `$request_uri`, and correctly
signals to browsers and search engines that the move is permanent —
preserving any existing SEO value and updating bookmarked links over time.

## Why were ACM, the HTTPS Listener, and the CloudWatch alarms left out of the provisioning scripts?

These are fundamentally different from the rest of the infrastructure in
one respect: they aren't things that get torn down and recreated
repeatedly during development. The core VPC/EC2/RDS stack was rebuilt many
times over the course of this project to test the scripts themselves — a
certificate, a domain-level redirect, and a set of alerting thresholds are
not. Automating genuinely one-time, rarely-changing steps has a real cost
(more code to write, test, and maintain) without a proportional benefit, so
they were deliberately left as documented manual steps instead.    
