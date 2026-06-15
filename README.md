# Event Data Platform

This project simulates a production-style data engineering pipeline for product event data.

## Current stage

Module 1 - Raw data generation and validation.

## Data fields

Each raw event contains:

- event_id
- user_id
- session_id
- event_type
- event_timestamp
- country
- device
- product_id
- price

## Generate data

```bash
python scripts/generate_events.py --date 2026-06-14 --num-events 10000
```

## Silver layer

The Silver layer creates validated and deduplicated event tables.

### Tables

- `SILVER.EVENTS_CLEAN` - valid events used for analytics
- `SILVER.EVENTS_REJECTED` - invalid or duplicate events with rejection reasons

### Data quality rules

Rows are rejected when:

- event_id is missing
- user_id is missing
- session_id is missing
- event_type is missing or invalid
- event_timestamp is missing
- device is not one of: ios, android, web
- country is not one of: IL, US, GB, DE, FR, ES
- purchase event has missing or invalid price
- product event has missing product_id
- event_id is duplicated

### Run

```bash
snowsql -a ... -u ... -f sql/04_create_silver_events.sql
```

## Gold layer

The Gold layer contains business-ready analytics tables built from `SILVER.EVENTS_CLEAN`.

### Tables

- `GOLD.DAILY_METRICS`
- `GOLD.EVENTS_BY_TYPE_DAILY`
- `GOLD.REVENUE_BY_COUNTRY_DAILY`
- `GOLD.CONVERSION_FUNNEL_DAILY`

### Example business questions

This layer can answer:

- How many daily active users do we have?
- How much revenue did we generate per day?
- Which event types are most common?
- Which countries generate the most revenue?
- What is the product conversion funnel?

### Run

```bash
snowsql -a ... -u ... -f sql/05_create_gold_tables.sql
```


## dbt Transformation Layer

This project uses dbt to manage the transformation pipeline from raw events to analytics-ready Gold tables.

### dbt Flow

```text
RAW.RAW_EVENTS
   ↓
bronze_events
   ↓
int_events_validated
   ↓
silver_events_clean
silver_events_rejected
   ↓
gold_daily_metrics
gold_events_by_type_daily
gold_revenue_by_country_daily
gold_conversion_funnel_daily
```