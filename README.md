# Snowflake dbt Event Data Platform

## Overview

This project is a production-style Data Engineering portfolio project that simulates an end-to-end event data platform.

It generates raw product event data locally, uploads JSONL files to Snowflake, loads them into a raw table, and transforms the data through a layered warehouse architecture using dbt. The pipeline is orchestrated with Airflow and includes data validation, rejected-record handling, dimensional modeling, source freshness checks, dbt snapshots, and lightweight CI.

The goal of the project is to demonstrate practical Data Engineering skills using a realistic ELT workflow.

## What This Project Demonstrates

* Local event data generation with Python
* File ingestion into Snowflake using SnowSQL
* Snowflake internal stages and `COPY INTO`
* Semi-structured JSON handling with `VARIANT`
* dbt Bronze, Silver, marts, and Gold modeling
* Data validation and rejected-record handling
* Star schema design with facts and dimensions
* dbt seeds for reference data
* dbt snapshots for product catalog history
* dbt source freshness checks
* Airflow orchestration with separate ingestion and transformation DAGs
* Lightweight GitHub Actions CI with `dbt parse`
* dbt documentation and lineage

## Architecture

```text
Python event generator
   ↓
Local JSONL files
   ↓
Airflow ingestion DAG
   ↓
Snowflake internal stage
   ↓
RAW.RAW_EVENTS
   ↓
dbt source()
   ↓
bronze_events
   ↓
int_events_validated
   ↓
silver_events_clean / silver_events_rejected
   ↓
Core marts
   ├── dim_users
   ├── dim_products
   ├── dim_dates
   ├── fact_events
   └── fact_purchases
   ↓
Gold analytics models
   ├── gold_daily_metrics
   ├── gold_events_by_type_daily
   ├── gold_revenue_by_country_daily
   └── gold_conversion_funnel_daily
```

## Tech Stack

* Python
* Snowflake
* SnowSQL
* dbt Core
* dbt Snowflake adapter
* Apache Airflow
* SQL
* GitHub Actions
* Git / GitHub

## Data Generation

Raw event data is generated locally using Python.

Each generated event can include:

* `event_id`
* `user_id`
* `session_id`
* `event_type`
* `event_timestamp`
* `country`
* `device`
* `product_id`
* `price`

Example command:

```bash
python scripts/generate_events.py \
  --date 2026-06-14 \
  --num-events 10000 \
  --bad-row-rate 0.02
```

Inspect a generated file:

```bash
python scripts/inspect_events.py \
  --file data/raw/events_2026-06-14.jsonl
```

The generator can also create intentionally invalid rows, which are used to test the validation and rejected-record logic in the Silver layer.

## Snowflake Loading

The project uses a Snowflake internal stage to upload local JSONL files before loading them into a raw table.

```text
Local JSONL file
   ↓ PUT
Snowflake internal stage
   ↓ COPY INTO
RAW.RAW_EVENTS
```

The raw table stores each event as a Snowflake `VARIANT`, preserving the original JSON structure.

Raw table:

```text
RAW.RAW_EVENTS
```

Main columns:

* `RAW_EVENT`
* `SOURCE_FILENAME`
* `LOADED_AT`

## Warehouse Layers

### Raw Layer

The Raw layer stores the original event payload with ingestion metadata.

This layer is intentionally close to the source data and keeps the raw JSON structure available for replay, debugging, and auditing.

### Bronze Layer

The Bronze layer parses raw JSON into typed columns.

dbt model:

```text
bronze_events
```

Example columns:

* `event_id`
* `user_id`
* `session_id`
* `event_type`
* `event_timestamp`
* `event_date`
* `country`
* `device`
* `product_id`
* `price`
* `source_filename`
* `loaded_at`

The Bronze model is incremental, so new raw rows can be processed without rebuilding the full table every time.

### Silver Layer

The Silver layer validates, deduplicates, and separates clean records from rejected records.

dbt models:

```text
int_events_validated
silver_events_clean
silver_events_rejected
```

Validation rules include:

* `event_id` must not be null
* `user_id` must not be null
* `session_id` must not be null
* `event_timestamp` must not be null
* `event_type` must be an accepted value
* `country` must be an accepted value
* `device` must be an accepted value
* Product-related events must have a `product_id`
* Purchase events must have a positive price
* Duplicate `event_id` values are rejected

Invalid records are not silently dropped. They are written to:

```text
silver_events_rejected
```

Each rejected row includes a `rejection_reason`, making data quality issues visible and auditable.

### Core Marts Layer

The Core marts layer models clean event data into a small star schema.

Dimensions:

```text
dim_users
dim_products
dim_dates
```

Facts:

```text
fact_events
fact_purchases
```

This layer separates business entities from business events and creates a cleaner base for analytics.

### Gold Layer

The Gold layer contains analytics-ready business tables.

dbt models:

```text
gold_daily_metrics
gold_events_by_type_daily
gold_revenue_by_country_daily
gold_conversion_funnel_daily
```

These models answer business questions such as:

* How many daily active users did we have?
* How many events happened per day?
* How much revenue was generated per day?
* Which countries generated the most revenue?
* What is the product view to purchase conversion funnel?

## dbt Features Used

The transformation layer is managed with dbt.

Key dbt features used:

* `source()` for Snowflake raw tables
* `ref()` for model dependencies
* Incremental model materialization
* Table materializations
* Ephemeral model for reusable validation logic
* Generic tests
* Custom data tests
* Seeds
* Snapshots
* Source freshness
* Model and column documentation
* dbt lineage graph

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

* `not_null`
* `unique`
* `accepted_values`
* `relationships`

Examples:

* `event_id` must be unique and not null in clean fact models
* `event_type` must be one of the accepted event types
* `device` must be one of the supported device values
* `fact_purchases.product_id` must exist in `dim_products`
* `fact_events.user_id` must exist in `dim_users`

The project also includes custom business-rule tests, including:

* Purchase events must have a price
* Purchase price must be positive
* Non-purchase events should not have a price
* Product-related events must have a `product_id`
* Rejected events must have a `rejection_reason`

## Source Freshness

The project includes a dbt source freshness check for the raw events table.

Source:

```text
source:raw.raw_events
```

Freshness configuration:

```text
loaded_at_field: LOADED_AT
warn_after: 12 hours
error_after: 24 hours
```

The Airflow dbt DAG runs source freshness before building downstream models.

```text
dbt_debug
   ↓
dbt_seed
   ↓
dbt_snapshot
   ↓
dbt_source_freshness
   ↓
dbt_run
   ↓
dbt_test
```

This helps ensure that transformations are not run on stale raw data.

## dbt Seeds

The project uses dbt seeds for small reference data.

Seed:

```text
products.csv
```

The product seed contains product catalog attributes such as:

* `product_id`
* `product_name`
* `category`
* `brand`
* `base_price`
* `is_active`
* `catalog_updated_at`

This seed is used to enrich the product dimension.

## dbt Snapshots

The project uses dbt snapshots to track product catalog changes over time.

Snapshot:

```text
products_snapshot
```

Snapshot configuration:

```text
unique_key: product_id
strategy: timestamp
updated_at: catalog_updated_at
```

The snapshot creates a slowly changing history table in Snowflake with dbt metadata columns such as:

* `dbt_valid_from`
* `dbt_valid_to`
* `dbt_updated_at`
* `dbt_scd_id`

Example use case:

If a product's base price changes, the snapshot keeps both the old and new versions instead of overwriting history.

## Airflow Orchestration

The project includes two Airflow DAGs.

### 1. Ingestion DAG

DAG:

```text
event_platform_ingestion_pipeline
```

Task flow:

```text
generate_events_file
   ↓
upload_file_to_snowflake_stage
   ↓
copy_into_raw_events
   ↓
trigger_dbt_pipeline
```

This DAG generates a daily JSONL event file, uploads it to a Snowflake internal stage, loads it into `RAW.RAW_EVENTS`, and then triggers the dbt transformation DAG.

### 2. dbt Transformation DAG

DAG:

```text
event_platform_dbt_pipeline
```

Task flow:

```text
dbt_debug
   ↓
dbt_seed
   ↓
dbt_snapshot
   ↓
dbt_source_freshness
   ↓
dbt_run
   ↓
dbt_test
```

This DAG loads reference data, captures product catalog history, checks raw source freshness, builds the dbt models, and runs dbt tests.

## CI

The repository includes a lightweight GitHub Actions CI workflow.

Workflow:

```text
.github/workflows/dbt-ci.yml
```

The CI workflow installs dbt and runs:

```bash
dbt parse
```

This validates that the dbt project structure, refs, sources, YAML files, and configuration can be parsed successfully without requiring live Snowflake credentials.

The CI is intentionally lightweight. It checks the dbt project structure without storing Snowflake credentials in GitHub secrets.

## Project Structure

```text
de-snowflake-event-platform/
  .github/
    workflows/
      dbt-ci.yml

  dags/
    event_platform_dbt_dag.py
    event_platform_ingestion_dag.py

  scripts/
    generate_events.py
    inspect_events.py
    start_airflow.sh

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
      marts/
        core/
      gold/
    seeds/
      products.csv
    snapshots/
      products_snapshot.sql

  data/
    raw/

  README.md
  .gitignore
```

## How to Run Locally

### 1. Create and activate a Python environment

From the project root:

```bash
python -m venv .venv
source .venv/bin/activate
```

Install dbt:

```bash
python -m pip install --upgrade pip
pip install dbt-core==1.11.11 dbt-snowflake==1.11.5
```

### 2. Generate raw data

```bash
python scripts/generate_events.py \
  --date 2026-06-14 \
  --num-events 10000 \
  --bad-row-rate 0.02
```

### 3. Set up Snowflake objects

Run the setup SQL in Snowflake:

```text
sql/01_setup_snowflake.sql
```

This creates the warehouse, database, schemas, raw table, stage, and file format.

### 4. Configure SnowSQL

Create a local SnowSQL connection named `event_platform`.

Example SnowSQL config section:

```ini
[connections.event_platform]
accountname = <your_snowflake_account>
username = <your_snowflake_username>
password = <your_snowflake_password>
warehousename = EVENT_PLATFORM_WH
dbname = EVENT_PLATFORM
schemaname = RAW
```

This config is local and should not be committed to the repository.

Test the connection:

```bash
snowsql -c event_platform
```

### 5. Upload and load raw data manually

Upload a local file to the Snowflake stage:

```sql
PUT 'file:///absolute/path/to/data/raw/events_2026-06-14.jsonl'
@RAW.RAW_EVENTS_STAGE
AUTO_COMPRESS=TRUE
OVERWRITE=TRUE;
```

Load the staged file into the raw table:

```sql
COPY INTO RAW.RAW_EVENTS (RAW_EVENT, SOURCE_FILENAME)
FROM (
    SELECT
        $1 AS RAW_EVENT,
        METADATA$FILENAME AS SOURCE_FILENAME
    FROM @RAW.RAW_EVENTS_STAGE
)
FILE_FORMAT = (FORMAT_NAME = RAW.JSONL_FORMAT)
PATTERN = '.*events_2026-06-14.*'
ON_ERROR = 'ABORT_STATEMENT';
```

### 6. Run dbt

```bash
cd event_platform_dbt

../.venv/bin/dbt seed --full-refresh
../.venv/bin/dbt snapshot
../.venv/bin/dbt source freshness
../.venv/bin/dbt run
../.venv/bin/dbt test
```

### 7. Start Airflow locally

From the project root:

```bash
./scripts/start_airflow.sh
```

Open the Airflow UI:

```text
http://localhost:8080
```

Trigger:

```text
event_platform_ingestion_pipeline
```

The ingestion DAG loads new raw data and then triggers the dbt transformation DAG.

## Example Validation Queries

Check row counts across layers:

```sql
USE WAREHOUSE EVENT_PLATFORM_WH;
USE DATABASE EVENT_PLATFORM;
USE SCHEMA DBT_DEV;

SELECT
    (SELECT COUNT(*) FROM BRONZE_EVENTS) AS bronze_rows,
    (SELECT COUNT(*) FROM SILVER_EVENTS_CLEAN) AS silver_clean_rows,
    (SELECT COUNT(*) FROM SILVER_EVENTS_REJECTED) AS silver_rejected_rows,
    (SELECT COUNT(*) FROM FACT_EVENTS) AS fact_events_rows,
    (SELECT COUNT(*) FROM FACT_PURCHASES) AS fact_purchases_rows,
    (SELECT COUNT(*) FROM GOLD_DAILY_METRICS) AS gold_daily_rows;
```

Check rejected records:

```sql
SELECT
    rejection_reason,
    COUNT(*) AS rejected_rows
FROM SILVER_EVENTS_REJECTED
GROUP BY rejection_reason
ORDER BY rejected_rows DESC;
```

Check product snapshot history:

```sql
USE DATABASE EVENT_PLATFORM;

SELECT
    product_id,
    product_name,
    base_price,
    catalog_updated_at,
    dbt_valid_from,
    dbt_valid_to
FROM DBT_SNAPSHOTS.PRODUCTS_SNAPSHOT
WHERE product_id = 'product_1'
ORDER BY dbt_valid_from;
```

## Interview Talking Points

This project demonstrates a realistic ELT pipeline using Snowflake, dbt, and Airflow.

Strong points to discuss:

* Raw event data is loaded into Snowflake before transformation, following an ELT pattern.
* Raw JSON is preserved in a `VARIANT` column for replay and debugging.
* dbt manages transformation logic using modular SQL models, tests, documentation, and lineage.
* The pipeline follows a layered warehouse architecture: Raw, Bronze, Silver, Core marts, and Gold.
* The Silver layer separates clean records from rejected records instead of silently dropping invalid data.
* The project includes a star schema with fact and dimension tables.
* Product reference data is managed using dbt seeds.
* Product catalog history is tracked using dbt snapshots.
* Airflow separates ingestion orchestration from dbt transformation orchestration.
* Source freshness checks prevent downstream models from running on stale raw data.
* GitHub Actions CI validates the dbt project structure without requiring live Snowflake credentials.

## Final Project Summary

This project simulates a realistic batch event data platform.

It covers ingestion, cloud loading, raw JSON storage, dbt transformations, data validation, rejected-record handling, dimensional modeling, analytics tables, product history tracking, source freshness, orchestration, and CI.

It is designed to demonstrate practical Data Engineering skills in a clear, explainable, portfolio-ready way.
