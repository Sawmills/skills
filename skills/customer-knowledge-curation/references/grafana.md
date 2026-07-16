# Grafana Playbook

## Contents

- Probe
- Datasources
- Dashboards
- Alerts and annotations

## Probe

Probe search, datasources, alert rules, annotations, and folders separately.
Viewer tokens often see dashboards but not datasources or alerting APIs.
Unviewable folders are gaps, not proof that nothing exists.

## Datasources

Read datasources first. They define the telemetry universe and the uid-to-name
map needed because dashboard panels usually reference datasource uids.

## Dashboards

Use folders and dashboard search to identify ownership, tiering, and component
families. Fetch dashboard JSON selectively because dashboards can be large and
panels can nest inside collapsed rows.

Dashboard JSON is the core curation signal:

- panel queries are metrics operators watch;
- template variables reveal the grains operators slice by;
- thresholds can imply SLOs or capacity limits;
- rows and folder names reveal team ownership.

## Alerts And Annotations

Read unified alert rules from provisioning or Grafana's Prometheus-compatible
alert API where available. Older alert definitions may live only inside
dashboard JSON.

Annotations are time-anchored operator knowledge. Use bounded windows and
pagination to find deploy markers, incident markers, and historical alert state.
