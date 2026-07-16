# Datadog Playbook

## Contents

- Probe
- Inventory
- Dependencies
- Monitors and dashboards
- Metric schema exploration
- Classification

## Probe

Detect the Datadog site and probe each readable surface independently: logs,
metrics, monitors, dashboards, RUM, APM, SLOs, synthetics, events, and notebooks.
Record unreadable surfaces and continue; a 403 on one endpoint must not stop the
sweep.

Always inspect the response `errors` field. A malformed query can return zero
data and look like absence.

## Inventory

Use logs `service` facet aggregation over a recent bounded window as the primary
service inventory. It often finds services that metrics, RUM, and dashboards
miss.

Use metric inventory for two jobs:

- grain input: label sets, group keys, and cardinality;
- idea generation: walk each in-scope metric family and ask what failure would
  move that metric.

Metric tags alone are a weak topology map. Prefer `service` plus
`kube_namespace` where available, then source-native identifiers for managed
services.

## Dependencies

Use the strongest available dependency source:

1. APM service dependencies.
2. RUM resource calls for frontend, backend, and external SaaS edges.
3. Log-content mining for peer, destination, timeout, and connection-refused
   fields.
4. Metric-tag co-occurrence as a last resort.

## Monitors And Dashboards

Read monitor definitions and state. Currently firing monitors are high-priority
leads; muted or downtimed monitors are known noise and should not be mirrored.

Dashboards plus monitors show what the team actually watches and how they tier
components. Dashboard widget queries can reveal databases, queues, caches, and
search clusters that emit no service logs.

SLOs, synthetics, and RUM identify committed user-facing latency, error, and
availability targets.

## Metric Schema Exploration

Metric schemas are required input, not fallback. Monitors and incidents only
teach failures someone already noticed. Schema exploration finds net-new
coverage such as cross-store consistency drift, error-signature counters,
queue alarms, backlog gauges, and lifecycle/completion signals.

## Classification

Separate customer-owned services from generated telemetry, demos, observability
data planes, platform operators, and third-party integrations. Collapse pod and
replica names into logical services unless the failure is specifically about
pod lifecycle.
