# Investigation And Census

## Contents

- Component census
- External service pass
- Incumbent-alert handling
- Coverage closure
- End-of-run report

## Component Census

Build the census before authoring. The scope is what is running, not what the
scope string or monitor names happen to mention.

Mechanically enumerate:

- every deployment and statefulset running in the scope's namespaces;
- every service emitting logs in those namespaces;
- every metric family present in those namespaces;
- one dependency hop out from each in-scope service;
- the queues, caches, stores, brokers, and backing clusters those services use;
- universal platform hygiene for all workloads, including crash loops, restart
  storms, desired replicas missed, and pods stuck pending.

Infrastructure under an in-scope service is in scope. A broker's disk, a search
cluster's shard health, or a cache's memory pressure can be the earliest signal
for an application failure.

## External Service Pass

Externally managed services often have no cluster, namespace, or workload tags.
Namespace-filtered inventory can miss hosted databases, search clusters, cloud
provider resources, or SaaS dependencies.

Run a second account-wide metric-prefix pass for vendor families that appear in
the account. Treat an absence claim with the same skepticism as a threshold:
verify it by prefix before recording "no metrics found."

## Incumbent Alerts

Incumbent alert rules are leads, not truth. They tell you which failure modes
operators care about, but they can be noisy, stale, inverted, or miscalibrated.

Use incumbents to find:

- failure names and operator language;
- source metrics and label grains;
- related dashboards and runbooks;
- past firing state and known noise.

Do not copy their threshold or window without measuring the live baseline.

## Coverage Closure

Every component ends in exactly one state:

- covered by one or more authored conditions;
- covered by an existing customer alert but not expressible through metric
  conditions, with the reason recorded;
- not visible in telemetry, with the failed queries or missing prefixes recorded;
- intentionally out of scope, with the reason recorded.

Never leave a census item silently unvisited.

## End-Of-Run Report

Produce a short handoff:

- conditions written;
- components covered;
- named gaps and why they remain gaps;
- sources that were unreadable or partially unreadable;
- high-risk incumbents skipped because they were chronic, inverted, or
  inexpressible;
- live-query evidence used for each threshold.
