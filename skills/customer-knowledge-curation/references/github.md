# GitHub And Code Playbook

## Contents

- Probe
- Service inventory
- Alerting as code
- Dependencies
- Emitted telemetry
- Operational knowledge

## Probe

Check auth status, rate limits, and repo visibility. Exclude archived repos and
forks unless the customer explicitly uses them operationally.

Choose strategy by repo shape:

- polyrepo: code search first;
- monorepo: shallow clone and local search.

## Service Inventory

Look for service catalogs, deploy manifests, Helm charts, Kustomize files,
Dockerfiles, and Kubernetes resources. Backstage-style catalog files are often
authoritative when present.

## Alerting As Code

Version-controlled alert logic is high value. Search for Prometheus rule files,
Datadog monitor resources, Alertmanager config, Grafana provisioning, and
Terraform alert definitions. Commit history around alert files explains why
thresholds moved.

## Dependencies

Use compose files, Helm values, environment variables, service mesh config,
client configuration, and endpoint names to map upstream and downstream
relationships.

## Emitted Telemetry

Search instrumentation calls and extract exact metric-name string literals.
Conditions must reference metrics services actually emit, not guessed names.

Use resource requests, limits, HPA specs, max replicas, queue worker counts, and
storage sizes as denominators for ratio and capacity rules.

## Operational Knowledge

Runbooks, postmortems, incident-labeled issues and PRs, ownership files, and
deployment history provide failure context and rollback or remediation paths.
Commits around incident dates often show the leading signal that would have
detected the failure earlier.
