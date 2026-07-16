---
name: customer-knowledge-curation
description: Use when using customer knowledge to build or maintain early-detection coverage.
---

# Customer Knowledge Curation

Use this skill to build broad early-detection coverage for a customer scope from
customer knowledge and live telemetry.

## Core Workflow

Two sources of coverage, in priority order:

- Customer knowledge tells you what to cover. Incumbent alerts and incidents name
  failure modes someone already paid to learn.
- Live telemetry fills the gaps. Use golden signals, dependency signals, and
  metric-schema exploration to find failure modes no incumbent watches yet.

Do not read the curator catalog while authoring. A skill run is an independent
source of customer knowledge; the curator converges overlaps downstream.

1. Build the component census before authoring.
2. Sweep the available customer sources.
3. Verify each candidate metric, label set, grain, and threshold against live data.
4. Author one condition per failure mode per telemetry source.
5. Write conditions through the Conditions API.
6. Verify only the ids you created.
7. End with covered components, named gaps, and unreadable sources.

## Required References

Read these direct references as the task requires:

- Component census and closure: [references/investigation.md](references/investigation.md)
- Datadog playbook: [references/datadog.md](references/datadog.md)
- Prometheus, VictoriaMetrics, and vmalert playbook:
  [references/prometheus-victoriametrics.md](references/prometheus-victoriametrics.md)
- Grafana playbook: [references/grafana.md](references/grafana.md)
- PagerDuty playbook: [references/pagerduty.md](references/pagerduty.md)
- GitHub/code playbook: [references/github.md](references/github.md)
- Conditions API and JSON schemas: [references/conditions-api.md](references/conditions-api.md)
- Quality bar and detector patterns: [references/quality-bar.md](references/quality-bar.md)

## Non-Negotiables

- Treat incumbent alerts as leads, not truth. Never inherit thresholds, windows,
  or predicates without measuring the live signal.
- Every component in scope ends covered or named as a gap with a reason.
- Verify absence claims by metric prefix before writing them down.
- Prefer service, namespace, workload, tenant, or source-native group grain.
  Avoid pod-grain clones except for failures whose entity really is the pod
  lifecycle, such as CrashLoopBackOff.
- Every condition proposal must have reviewable evidence in the handoff: query,
  lookback window, normal range, observed incident or anomaly range, and
  threshold rationale.
- Do not post test-named, scratch, or experimental condition ids.

## Conditions API

Use the metric Conditions API only. Do not create log conditions through this
surface.

- Create: `POST /api/conditions`
- Verify own writes: `GET /api/conditions/:id`
- Delete: `DELETE /api/conditions/:id` only when explicitly given an obsolete,
  invalid, or stale condition id.

Do not use collection reads as an authoring step, and do not amend existing
coverage with `PUT`; the curator owns convergence and maintenance.

## Safety

Customer systems are read-only. The only normal mutation is writing metric
conditions to the curator API, and deletion only when explicitly instructed with
an id.

Bound exploratory queries before grouping over high-cardinality dimensions.
Never invent customer context, source names, labels, incidents, runbooks, or
thresholds. If source binding is ambiguous, stop and set an explicit
`telemetry_source.source_name`.
