# Snowflake dbt Event Data Platform

## Overview

This project simulates a production-style Data Engineering pipeline for product event data.

It generates raw user event files locally, loads them into Snowflake, and transforms them through a layered warehouse architecture using dbt.

The goal of the project is to demonstrate practical Data Engineering skills:

* raw data ingestion
* Snowflake staging and loading
* semi-structured JSON handling
* Bronze, Silver, and Gold data modeling
* dbt transformations
* data quality tests
* lineage and documentation
* analytics-ready business tables

## Architecture

```text
Python event generator
   ↓
Local JSONL files
   ↓
Snowflake internal stage
   ↓
RAW.RAW_EVENTS
   ↓
dbt source()
   ↓
BRONZE_EVENTS
   ↓
INT_EVENTS_VALIDATED
   ↓
SILVER_EVENTS_CLEAN
SILVER_EVENTS_REJECTED
   ↓
GOLD_DAILY_METRICS
GOLD_EVENTS_BY_TYPE_DAILY
GOLD_REVENUE_BY_COUNTRY_DAILY
GOLD_CONVERSION_FUNNEL_DAILY
```

## Tech Stack

* Python
* Snowflake
* SnowSQL
* dbt Core
* dbt Snowflake adapter
* SQL
* Git / GitHub

## Data Generation

Raw event data is generated with Python as JSONL files.

Each event contains:

* event_id
* user_id
* session_id
* event_type
* event_timestamp
* country
* device
* product_id
* price

Example command:

```bash
python scripts/generate_events.py --date 2026-06-14 --num-events 10000
```

Inspect generated data:

```bash
python scripts/inspect_events.py --file data/raw/events_2026-06-14.jsonl
```

## Snowflake Loading

The project uses a Snowflake internal stage to upload local JSONL files before loading them into a raw table.

Flow:

```text
local JSONL file
   ↓ PUT
Snowflake internal stage
   ↓ COPY INTO
RAW.RAW_EVENTS
```

The raw table stores each event as a Snowflake `VARIANT`, preserving the original JSON structure.

## Warehouse Layers

### Raw Layer

The raw layer stores the original JSON event object with metadata.

Table:

```text
RAW.RAW_EVENTS
```

Main columns:

* RAW_EVENT
* SOURCE_FILENAME
* LOADED_AT

### Bronze Layer

The Bronze layer parses the raw JSON into typed columns.

dbt model:

```text
bronze_events
```

Example columns:

* event_id
* user_id
* session_id
* event_type
* event_timestamp
* event_date
* country
* device
* product_id
* price

### Silver Layer

The Silver layer validates and deduplicates the data.

dbt models:

```text
int_events_validated
silver_events_clean
silver_events_rejected
```

Validation rules include:

* event_id must not be null
* user_id must not be null
* session_id must not be null
* event_timestamp must not be null
* event_type must be an accepted value
* country must be an accepted value
* device must be an accepted value
* purchase events must have a valid positive price
* product events must have product_id
* duplicate event_id values are rejected

Invalid records are not silently dropped. They are stored in `silver_events_rejected` with a rejection reason.

### Gold Layer

The Gold layer creates analytics-ready business tables.

dbt models:

```text
gold_daily_metrics
gold_events_by_type_daily
gold_revenue_by_country_daily
gold_conversion_funnel_daily
```

These tables answer business questions such as:

* How many daily active users did we have?
* How many events happened per day?
* How much revenue was generated per day?
* Which countries generated the most revenue?
* What is the user conversion funnel from product view to purchase?

## dbt

The transformation layer is managed with dbt.

Key dbt features used:

* `source()` for existing Snowflake raw tables
* `ref()` for model dependencies
* table materializations
* ephemeral model for reusable validation logic
* generic tests
* model and column documentation
* lineage graph through dbt docs

Run dbt:

```bash
cd event_platform_dbt

../.venv/bin/dbt run
../.venv/bin/dbt test
```

Generate dbt docs:

```bash
../.venv/bin/dbt docs generate
../.venv/bin/dbt docs serve
```

## Data Quality

The project includes dbt tests such as:

* not_null
* unique
* accepted_values

Examples:

* `event_id` must be unique and not null
* `event_type` must be one of the allowed event types
* `country` must be one of the supported country codes
* `device` must be one of `ios`, `android`, or `web`

## Example Validation Query

```sql
USE WAREHOUSE EVENT_PLATFORM_WH;
USE DATABASE EVENT_PLATFORM;
USE SCHEMA DBT_DEV;

SELECT
    (SELECT COUNT(*) FROM BRONZE_EVENTS) AS bronze_rows,
    (SELECT COUNT(*) FROM SILVER_EVENTS_CLEAN) AS silver_clean_rows,
    (SELECT COUNT(*) FROM SILVER_EVENTS_REJECTED) AS silver_rejected_rows,
    (SELECT COUNT(*) FROM GOLD_DAILY_METRICS) AS gold_daily_rows,
    (SELECT COUNT(*) FROM GOLD_CONVERSION_FUNNEL_DAILY) AS gold_funnel_rows;
```

Expected output for the initial dataset:

```text
bronze_rows            46000
silver_clean_rows      46000
silver_rejected_rows   0
gold_daily_rows        4
gold_funnel_rows       4
```

## Project Structure

```text
de-snowflake-event-platform/
  scripts/
    generate_events.py
    inspect_events.py

  sql/
    01_setup_snowflake.sql
    02_load_raw_events.sql
    03_create_bronze_events.sql
    04_create_silver_events.sql
    05_create_gold_tables.sql

  event_platform_dbt/
    dbt_project.yml
    models/
      sources.yml
      bronze/
      silver/
      gold/

  data/
    raw/

  README.md
  requirements.txt
  requirements-lock.txt
  .gitignore
```

## How to Run

### 1. Create and activate Python environment

```bash
python -m venv .venv
source .venv/bin/activate
```

### 2. Install dependencies

```bash
pip install -r requirements.txt
```

### 3. Generate raw data

```bash
python scripts/generate_events.py --date 2026-06-14 --num-events 10000
python scripts/generate_events.py --date 2026-06-15 --num-events 12000
python scripts/generate_events.py --date 2026-06-16 --num-events 15000
python scripts/generate_events.py --date 2026-06-17 --num-events 9000
```

### 4. Set up Snowflake objects

Run the setup SQL in Snowflake:

```text
sql/01_setup_snowflake.sql
```

### 5. Upload files to the Snowflake stage

Use SnowSQL or a Snowflake worksheet session to upload local files to the internal stage.

### 6. Load raw files into Snowflake

Run:

```text
sql/02_load_raw_events.sql
```

### 7. Run dbt models

```bash
cd event_platform_dbt

../.venv/bin/dbt run
../.venv/bin/dbt test
```

### 8. Generate documentation

```bash
../.venv/bin/dbt docs generate
../.venv/bin/dbt docs serve
```

## Interview Talking Points

This project demonstrates an ELT approach using Snowflake and dbt.

Raw event data is loaded first into Snowflake and preserved as semi-structured JSON. dbt then manages the transformation layer using modular SQL models, dependency management, tests, documentation, and lineage.

The pipeline follows a Bronze, Silver, and Gold architecture:

* Bronze parses raw JSON into typed columns
* Silver validates, deduplicates, and separates rejected records
* Gold creates business-ready tables for product analytics

This structure makes the pipeline easier to test, debug, rebuild, and explain.
