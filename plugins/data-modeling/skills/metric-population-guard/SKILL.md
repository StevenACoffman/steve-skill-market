---
name: metric-population-guard
description: "Load when writing SQL, functions, semantic-layer metrics, charts or lists for a rate, count or KPI: a rate per tier/plan/segment or parameterized by segment, conversion or retention by signup week/cohort, active or slipping customer lists from recent invoices/charges, totals from tables with status/test/sandbox columns, a certified metric reused for a segment, or daily/weekly buckets."
---
# Metric Population Guard

Use while writing metric, rate, count or KPI queries and outcome labels. Before handing over, check each item that applies; skip the rest. A found trap is fixed in the delivered query/function/chart itself; a warning beside unchanged SQL is not a fix.

## Segment filter on numerator only
- **Spot:** a rate where the segment condition (tier, plan, region, a parameter) appears in the numerator's FILTER/CASE but the denominator is `COUNT(*)` over all rows or a separate subquery with no segment condition. Parameterizing it per segment copies the bug.
- **Why it breaks:** it returns the segment's share of all units, not its rate.
- **Do:** apply the same segment condition to the denominator (WHERE on both, or GROUP BY segment) and say you changed it.
- **Not applicable:** the segment filter is already in WHERE or GROUP BY, so both sides share it.

## Outcome measured before its window closes
- **Spot:** a rate by cohort/signup/origination period whose outcome needs time: converted, paid, retained, reopened, defaulted, an ML label. Look for a described delay (trial length, payment terms, "within N days", "ever") and recent periods included.
- **Why it breaks:** recent units have not had time to reach the outcome, so the latest periods are biased.
- **Do:** compute maturity = cohort length + window + lag (e.g. 7-day cohort + 14-day window + 2-day lag) and keep only cohorts with `cohort_start + maturity <= CURRENT_DATE`; to keep N points, shift the whole range back rather than shrinking it.
- **Not applicable:** the request states every reported period's window has already closed.

## Day/week boundaries undeclared
- **Spot:** hour/day/weekday/week buckets on UTC timestamps for sites in several zones, or weekly numbers compared across systems.
- **Why it breaks:** UTC midnight and differing week starts move local activity into the wrong day or week.
- **Do:** bucket in local time: `ts AT TIME ZONE tz` for timestamptz; `(ts AT TIME ZONE 'UTC') AT TIME ZONE tz` for a naive UTC timestamp. Align week starts before reconciling.
- **Not applicable:** the query already converts to each site's zone.

## Status/type flags not classified
- **Spot:** the table shown has status/state, type, is_test, sandbox, internal, cancelled, voided, comped or partner values, or company email domains, and the query does not filter them.
- **Why it breaks:** test, internal and cancelled records count as real business.
- **Do:** decide in/out for every value, encode it in WHERE, and state the decisions.
- **Not applicable:** the query already filters these columns, or the table has none. Never add filters on columns not shown.

## Reused metric excludes the requested segment
- **Spot:** a certified metric/view reused for a segment that its definition's filter (`NOT IN (...)`, `<> ...`, `= 'physical'`) removes.
- **Why it breaks:** it returns empty, zero or another population's number.
- **Do:** say so; query the underlying measure or define a separate metric for the segment. A query-time filter cannot undo the definition's filter.
- **Not applicable:** the definition's filters do not touch the requested segment.

## Activity window shorter than the customer cycle
- **Spot:** "active" means an invoice/charge/login in the last N days, while billing intervals include quarterly, annual, prepaid, multi-year or pauses.
- **Why it breaks:** those customers fall out between bills, so they appear inactive or slipping.
- **Do:** deliver a corrected query: activity from subscription coverage (`period_start <= d AND d < period_end`) or a per-billing-interval window (monthly 31, quarterly 93, annual 366 days); state the change.
- **Not applicable:** activity is defined by term or period coverage at the date.

## Not applicable when
- An item whose Spot is absent or whose Not-applicable cue holds: say nothing about it and just do the task. No guard checklists, verification steps, extra filters or renaming.
