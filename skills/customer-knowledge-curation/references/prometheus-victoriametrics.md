# Prometheus, VictoriaMetrics, And Vmalert Playbook

## Contents

- Probe
- Inventory
- Rules and state
- Grain and cardinality
- Gaps and batch metrics
- Classification

## Probe

Probe query, rules, targets, and TSDB status separately. Agent-mode Prometheus
may have no rules. In VictoriaMetrics clusters, series can live behind vmselect
while rules and targets live behind vmalert or vmagent.

VictoriaMetrics cluster paths can be tenant-prefixed. Do not trust empty
success: it can mean no data, wrong tenant, wrong time range, or insufficient
lookback. Label and series APIs often default to a recent window, so pass
explicit `start` and `end`.

## Inventory

Use `/api/v1/labels` to learn label keys, then label values for `job`,
`service`, `app`, and `namespace`. `job` is scrape-config truth. Beware limits
that truncate silently.

For dependency signals, probe caller/callee-labeled metrics such as service mesh,
ingress, HTTP client, database client, or queue client metrics. If those do not
exist, fall back to namespace co-location and alert-expression references.

## Rules And State

Read alerting rules for expressions, `for` windows, labels, annotations, and
per-alert firing state. Read firing alerts for the current hot set.

Recording rules are curation signal: they show what operators pre-compute and
watch. Group and file names often reveal ownership and distinguish hand-written
rules from vendored defaults.

## Grain And Cardinality

Use TSDB status and label cardinality before choosing entity grain. Aggregate
away per-run ids and replica churn. Prefer the operator action unit: service,
deployment, workload, namespace, tenant, or source-native resource id.

## Gaps And Batch Metrics

Use active targets and `up == 0` to find scrape gaps. If a service appears in
rules but not targets, record the blind spot.

For batch jobs, instant `rate` is usually wrong once metrics go stale. Use
`last_over_time`, `increase`, `max_over_time`, or explicit completion timestamps
for cron, job, and Pushgateway-style signals.

## Classification

Classify platform namespaces, monitoring namespaces, exporters, and vendored
rule files separately from customer-owned services. Imported defaults are not
the same as operator-curated knowledge.
