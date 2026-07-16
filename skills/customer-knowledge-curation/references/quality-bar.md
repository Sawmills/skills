# Quality Bar

## Contents

- Evidence
- Detector shape
- Grain
- Reusable detector patterns
- Safety checks

## Evidence

Every condition must be grounded. Confirm metric names and labels exist before
authoring, with no exceptions.

Record evidence in `context.evidence`:

- exact metric or query family checked;
- lookback window;
- normal range;
- incident, anomaly, or known-failure range when available;
- threshold rationale;
- grain rationale when the grain is not obvious.

An empty evidence field means "I guessed."

## Detector Shape

Prefer expressions that become true when failure starts. Avoid chronic-true
rules, activity rules posing as failure rules, and thresholds set below measured
normal behavior.

Breadth is welcome, but only for grounded candidates. The curator can demote
noise later; it cannot recover trust in conditions that were guessed.

## Grain

Use the entity operators act on: service, workload, namespace, tenant, queue,
cluster, index, database, or source-native resource id. Pod grain is usually
ephemeral churn. Use it only for pod-lifecycle failures where the pod is the
actual entity, then group by stable owner labels when available.

One failure mode should usually be one grouped rule. When the same signal exists
across services, namespaces, or tenants, filter all of them and group by the
distinguishing label. Split rules only when signals or thresholds genuinely
differ, and record why.

## Reusable Detector Patterns

- Cross-store consistency drift: compare equivalent counts or state across two
  systems that should agree.
- Log-only incumbent proxy: if a log or event alert cannot be expressed through
  metric conditions, look for queue depth, consumer count, shard state, alarm
  gauge, lifecycle counter, completion timestamp, or error-signature metric
  proxies. If no metric proxy exists, record a named gap.
- Onset plus burst: one failure mode can need a short-window onset detector and
  a longer sustained or burst detector. Baseline both windows before writing.
- Capacity level plus rate: pair static thresholds, such as low free disk, with
  rate-of-change detectors for fast drains.
- Slow-burn degradation: add long-window companions for availability,
  redundancy, or under-replication states that can sit degraded for days.
- Golden signals: cover latency, errors, saturation, traffic, and backpressure
  for every service where metrics exist.

## Safety Checks

- No test, scratch, demo, or temporary condition ids.
- No thresholds copied from incumbents without baseline evidence.
- No source names, labels, incidents, or runbooks invented from context.
- No unbounded high-cardinality exploratory queries.
- No customer-system mutations outside the Conditions API write/delete rules.
