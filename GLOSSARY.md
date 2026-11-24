# Customer Knowledge Curation

The Customer Knowledge Curation skill uses existing operational knowledge and
live telemetry to establish early-detection coverage. It inventories components,
measures candidate rules, and reports coverage and gaps.

## Language

### Coverage and Discovery

**Early-Detection Coverage**:
The failure modes watched for across a customer's components in scope.

**Customer Knowledge**:
Existing alerts, incident records, runbooks, and other records that identify
failure modes worth investigating.

**Component Census**:
An inventory of the workloads, emitted telemetry, and direct dependencies in
scope. It includes the infrastructure that supports the running services.

**External Service Pass**:
An account-wide review of metric prefixes for managed dependencies that can
lack labels for local workloads.

**Incumbent Alert**:
An existing alert rule that points to a known failure mode. Its query and
firing history guide what to measure in live telemetry.

**Failure Mode**:
A specific way a component can degrade or fail that warrants detection.

**Coverage Gap**:
A missing piece of metric Monitor coverage for a named failure mode or
component. The report records why the gap remains.

**Coverage Closure**:
The outcome recorded for each item in the Component Census. It accounts for
authored coverage, existing alerts whose failure modes lack a metric rule,
gaps in telemetry, and deliberate exclusions.

### Monitor Design

**Monitor**:
A rule that watches one query of an organization's telemetry and triggers past
a threshold. The skill authors metric Monitors, called conditions in its
interface.
_Avoid_: detector, alert rule

**Telemetry Source**:
The configured source of the metrics a Monitor evaluates. Each rule targets one
source, which is named explicitly when the organization has multiple sources.

**Grain**:
The level at which measurements are grouped for detection, such as by service
or workload. It identifies the kind of entity the Monitor watches.

**Baseline**:
The normal range observed for a candidate measurement at the chosen Grain
over a stated Lookback Window.

**Lookback Window**:
The span of live telemetry examined to measure normal or failure behavior for
a proposed Monitor.

**Threshold**:
The measurement boundary used to decide when a Monitor triggers. Evidence
relates the chosen boundary to normal behavior and any observed failures.

**Metric Proxy**:
A metric that can detect a failure mode first described by a log or event alert.

**Monitor Context**:
Supporting information saved with a Monitor to aid investigation, such as
related queries, component relationships, and search terms.

### Evidence and Verification

**Evidence**:
The observations that justify a proposed Monitor and its Threshold. The report
records the query, Lookback Window, normal range, and available failure range.

**Write Verification**:
Confirmation of a Monitor creation or amendment through the write response or a
fresh read of the saved rule.

**End-of-Run Report**:
A record of Monitors written, components covered, named gaps, unreadable
sources, and the live Evidence used for each Threshold.
