# Conditions API

## Contents

- Lifecycle
- PromQL-backed condition
- Datadog-backed condition
- Source targeting
- Downstream effects

## Lifecycle

Use the metric Conditions API:

```http
POST   /api/conditions
GET    /api/conditions/:id
DELETE /api/conditions/:id
```

Rules:

1. Create with `POST /api/conditions`.
2. Suffix every condition id with a creation timestamp in the form
   `_HHMMDDMMYYYY`, such as `checkout_api_error_ratio_onset_093415072026`.
3. Verify only your own writes with `GET /api/conditions/:id` or the POST
   response.
4. Delete only when explicitly given the id of a condition that is obsolete,
   invalid, or pointed at a signal that no longer exists.

Do not create log conditions through this surface.

## PromQL-Backed Condition

For PromQL-backed sources, the expression lives in `bool_expr` as a boolean
PromQL expression.

```json
{
  "id": "checkout_api_error_ratio_onset_093415072026",
  "family": "checkout",
  "bool_expr": "sum by (namespace, service) (rate(http_requests_total{service=\"checkout-api\",code=~\"5..\"}[5m])) / sum by (namespace, service) (rate(http_requests_total{service=\"checkout-api\"}[5m])) > bool 0.05",
  "entity_grain": ["tenant", "namespace", "service"],
  "severity": "warning",
  "source": "agent",
  "target_firings_per_day": 1,
  "covers": ["Checkout API 5xx rate high"],
  "telemetry_source": {
    "telemetry_type": "metrics",
    "source_name": "victoriametrics-primary"
  },
  "context": {
    "component": "checkout-api",
    "related_metrics": [
      "rate(http_requests_total{service=\"checkout-api\"}[5m])"
    ],
    "likely_causes": ["bad deploy", "downstream dependency failing"],
    "evidence": "7d baseline: error ratio 0.1-0.8% normally, observed incident peak 9%; threshold 5% sits above normal readings"
  }
}
```

## Datadog-Backed Condition

For Datadog-backed sources, there is no `bool_expr`; use `datadog_scalar`.

```json
{
  "id": "payment_worker_consumers_zero_093415072026",
  "family": "payments",
  "entity_grain": ["tenant", "datadog_group"],
  "severity": "critical",
  "source": "agent",
  "target_firings_per_day": 1,
  "covers": ["No payment-worker consumers"],
  "telemetry_source": { "telemetry_type": "metrics", "source_name": "datadog-primary" },
  "datadog_scalar": {
    "window": "30m",
    "formula": "a",
    "queries": [
      {
        "name": "a",
        "query": "min:rabbitmq.queue.consumers{rabbitmq_queue:payments.worker.queue} by {kube_namespace}",
        "aggregator": "min"
      }
    ],
    "threshold": 1,
    "comparator": "<"
  },
  "context": {
    "component": "payment-worker",
    "likely_causes": ["consumers crashed or disconnected"],
    "evidence": "verified live over 7d: every namespace runs 2-5 consumers; zero never occurs during normal operation"
  }
}
```

`datadog_scalar` queries are named `a`, `b`, and so on. `formula` combines
them. The formula value over `window`, reduced by each query's `aggregator`, is
compared against `threshold` with `comparator`. The Datadog `by {...}` clause
defines the firing entities represented by `datadog_group`.

## Source Targeting

One runnable condition targets one source. In multi-source orgs, always set
`telemetry_source` explicitly. On this surface `telemetry_type` is `metrics`,
and `source_name` must name a telemetry source the curator instance knows.

If the same rule should cover multiple sources, create one condition per source.
Do not guess, alias, or merge sources.

Do not send server-owned fields such as `signal`, `status`, `authority`,
`calibration`, or deployment scoping fields.

## Downstream Effects

A posted condition can become live detection within minutes. The evaluator runs
conditions against live telemetry; true expressions can create firings that flow
to triage and notifications.

Size `target_firings_per_day` deliberately. Escalation authority is assigned
server-side, but `severity` and context influence downstream judgment.
