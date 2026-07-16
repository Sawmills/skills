# PagerDuty Playbook

## Contents

- Probe
- Service inventory
- Incident history
- Priority and noise
- Classification

## Probe

Start with identity and abilities endpoints. Scoped tokens can fail per-surface;
record blocked surfaces and continue.

## Service Inventory

List services with escalation policies, teams, and integrations. PagerDuty is
the customer's map of what pages humans and who owns it.

Use business services and service dependencies when configured. They are often
incomplete, so absence here is not an absence claim for runtime dependencies.

## Incident History

Incident history is the highest-signal input. Each incident can name the
failure mode, originating alert, source metric, urgency, responders, and human
notes.

Slice large date ranges into API-safe windows and fetch trigger log entries
where available. For notable incidents, read log entries, alerts, and notes.
Reference incidents in condition `covers` or context using the customer's own
incident key, for example `incident:INC-2041`.

## Priority And Noise

Priority, urgency, support hours, auto-resolve behavior, and incident duration
show the customer's severity ladder. Incidents that auto-resolve quickly or are
low-urgency can be known noise; do not mirror them blindly.

## Classification

Skip test, demo, disabled, integration-less, and long-silent services unless
other evidence shows they are real coverage targets.
