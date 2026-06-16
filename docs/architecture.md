# Architecture

This project follows an ELT architecture using Snowflake and dbt.

## High-level Flow

```mermaid
flowchart TD
    A[Python Event Generator] --> B[Local JSONL Files]
    B --> C[Snowflake Internal Stage]
    C --> D[RAW.RAW_EVENTS]
    D --> E[dbt Source]
    E --> F[bronze_events]
    F --> G[int_events_validated]
    G --> H[silver_events_clean]
    G --> I[silver_events_rejected]
    H --> J[gold_daily_metrics]
    H --> K[gold_events_by_type_daily]
    H --> L[gold_revenue_by_country_daily]
    H --> M[gold_conversion_funnel_daily]
```

## Layer Responsibilities

### Raw

Stores the original JSON event data as semi-structured `VARIANT`.

Purpose:

* preserve the source data
* allow rebuilds from raw
* keep loading logic separate from transformation logic

### Bronze

Parses raw JSON into typed columns.

Purpose:

* extract event fields
* cast timestamps and numeric values
* make raw data easier to query

### Silver

Applies validation, deduplication, and business rules.

Purpose:

* keep clean valid events
* separate rejected records
* make data quality issues observable

### Gold

Creates business-ready analytics tables.

Purpose:

* daily active users
* revenue metrics
* event distribution
* revenue by country
* user conversion funnel

## dbt Lineage

The dbt model flow is:

```text
source.raw.raw_events
   ↓
bronze_events
   ↓
int_events_validated
   ↓
silver_events_clean
   ↓
gold_daily_metrics
gold_events_by_type_daily
gold_revenue_by_country_daily
gold_conversion_funnel_daily
```

`silver_events_rejected` also depends on `int_events_validated` and stores invalid or duplicate records with a rejection reason.
