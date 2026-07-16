---
name: customer-knowledge-curation
description: Use when using customer knowledge to build or maintain early-detection coverage.
---

# Customer Knowledge Curation

Use this skill when using customer knowledge to build or maintain early-detection coverage.

This is the client-side/operator workflow for helping the detection system with customer
context: what systems matter, which incidents or incumbent monitors should be covered,
which telemetry sources are in scope, and how that knowledge becomes conditions in the
curator's catalog.

## The Workflow: Knowledge First

Operator knowledge is the highest-value input the detection system can get — mine it and
ship it as conditions:

1. **Investigate the org's resources.** Sweep everything reliable and available: code
   (services, deploy manifests, emitted metrics), Datadog (logs, monitors), PagerDuty,
   Prometheus/Grafana/VictoriaMetrics (live metrics, dashboards, recording rules), docs,
   runbooks, ownership notes. Above all: **old alerts and past incidents** — every
   incumbent alert rule and every incident ticket encodes a failure mode someone already
   paid to learn. Verify each candidate metric and its labels actually exist in the
   target telemetry source before authoring.
2. **Hand-author conditions from that knowledge** and ship them to the curator via the
   Conditions API (`POST /api/conditions`, one per failure mode, one per source).
   Incumbent alerts map to `covers` entries; incidents map to onset detectors that fire
   earlier than the alert that caught them last time.

## Investigation Checklist (step 1)

- Existing curator coverage: `GET /api/conditions` — never author blind.
- Incumbent alert rules (vmalert/Prometheus rules, Datadog monitors): expressions, label
  grains, and windows are proven operational knowledge — reuse their semantics, aim earlier.
- Incident history (tickets, PagerDuty): each incident names the metric that moved and the
  mode that was missed. Reference incidents in `covers`/`source` (e.g. `incident:SAW-1234`).
- Service code + deploy manifests: emitted metrics, resource limits (memory/CPU), replica
  counts, health thresholds — these ground runtime conditions.
- Live telemetry: confirm metric names, label sets, cardinality (aggregate away per-run
  IDs), freshness/sparsity (cron-emitted and error-only counters need
  `increase`/`last_over_time` windows, never instant `rate`).
- Scrape gaps: if a service's own metrics are not collected, say so explicitly and fall
  back to what is visible (e.g. cAdvisor `container_*`), and flag the gap to the operator.

## Conditions API (step 2)

Use the Conditions API to ship hand-authored conditions and for targeted lifecycle changes:

```http
GET    /api/conditions
GET    /api/conditions/:id
POST   /api/conditions
PUT    /api/conditions/:id
DELETE /api/conditions/:id
```

The API manages metric conditions. Do not create log conditions through this surface.

Lifecycle rules:

1. Read existing coverage with `GET /api/conditions` first.
2. If coverage is missing, create a condition with `POST /api/conditions`.
3. If coverage exists but is wrong or incomplete, read it with `GET /api/conditions/:id`,
   then amend it with `PUT /api/conditions/:id`.
4. If a condition is obsolete, invalid, or points at a signal that no longer exists,
   delete it with `DELETE /api/conditions/:id`.

Caveat: CRUD writes apply directly — they do NOT pass an admission gate/backtest. The
quality bar below is the only gate; the hourly curator's calibration and
defective-detector feedback are the safety net. Prefer expressions that are
provably onset-shaped (see quality bar) since no backtest will catch chronic-true noise
at write time.

### Condition JSON

Send metric condition JSON without server-owned fields:

```json
{
  "id": "exporter_send_failed",
  "family": "otel-exporter",
  "bool_expr": "rate(otelcol_exporter_send_failed_metric_points_total[5m]) > bool 25",
  "entity_grain": ["tenant", "collector", "pod"],
  "severity": "warning",
  "source": "agent",
  "target_firings_per_day": 1,
  "covers": [],
  "telemetry_source": {
    "telemetry_type": "metrics",
    "source_name": "vm-tenant-0"
  },
  "context": {
    "component": "otel-exporter",
    "related_metrics": [
      "rate(otelcol_exporter_send_failed_metric_points_total[5m])"
    ],
    "likely_causes": ["destination unavailable", "backend refusing writes"]
  }
}
```

Server-owned fields include `signal`, `status`, `authority`, `calibration`, and deployment scoping fields.
Do not send them. `entity_grain` is required: when the expression aggregates with `by (...)`,
the grain is that clause's labels; for non-aggregated expressions (like the example
above), use the metric's identifying labels that firings should group by (here
`["tenant", "collector", "pod"]`).

### Source Targeting

One runnable condition targets one source. In multi-source orgs, always set
`telemetry_source` explicitly — on this surface `telemetry_type` is always `metrics`,
and `source_name` must name a telemetry source the curator instance knows.
Unbound conditions can fail with ambiguous source resolution:

```text
multiple telemetry sources configured ... pass source_name explicitly
```

If the same rule should cover multiple sources, create one condition per source. Do not
guess, alias, or merge sources.

After shipping, verify the catalog actually changed (`GET /api/conditions`, or the
`/api/curator-changes` feed) — compare condition counts before and after.

## Quality Bar

- Prefer one clear metric expression over a broad collection of guesses.
- Confirm the metric and labels exist before authoring.
- Prefer expressions that become true when the failure starts, not expressions that are
  always true during normal operation. If a mirror of an incumbent alert would be
  chronically true (e.g. a fleet where most entities already sit in the failed state),
  skip it and flag the blocker instead of shipping noise.
- Prefer ratios against spec/limit metrics over hardcoded absolute thresholds where both
  exist (survives limit changes).
- Add useful context: component, related metrics, upstream/downstream relationships,
  likely causes, and only verified runbook links.
- Do not edit catalog files directly.
- Do not mutate customer systems.

## Safety

- Do not mutate customer systems.
- Do not bypass proposal gates, backtests, or admission checks.
- Do not hand-edit catalog files.
- Do not invent customer context, source names, labels, incidents, or runbooks.
- If source binding is ambiguous, stop and set `telemetry_source` with an explicit
  `source_name`.
