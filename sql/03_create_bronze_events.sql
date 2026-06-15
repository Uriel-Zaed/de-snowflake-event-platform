-- ============================================================
-- 03_create_bronze_events.sql
-- Purpose: Convert raw JSON events into typed bronze table
-- ============================================================

USE WAREHOUSE EVENT_PLATFORM_WH;
USE DATABASE EVENT_PLATFORM;

CREATE OR REPLACE TABLE BRONZE.EVENTS AS
WITH parsed_events AS (
    SELECT
        RAW_EVENT:event_id::STRING AS event_id,
        RAW_EVENT:user_id::STRING AS user_id,
        RAW_EVENT:session_id::STRING AS session_id,
        RAW_EVENT:event_type::STRING AS event_type,

        TRY_TO_TIMESTAMP_NTZ(
            RAW_EVENT:event_timestamp::STRING
        ) AS event_timestamp,

        RAW_EVENT:country::STRING AS country,
        RAW_EVENT:device::STRING AS device,
        RAW_EVENT:product_id::STRING AS product_id,

        TRY_TO_DECIMAL(
            RAW_EVENT:price::STRING,
            10,
            2
        ) AS price,

        SOURCE_FILENAME AS source_filename,
        LOADED_AT AS loaded_at
    FROM RAW.RAW_EVENTS
)

SELECT
    event_id,
    user_id,
    session_id,
    event_type,
    event_timestamp,
    TO_DATE(event_timestamp) AS event_date,
    country,
    device,
    product_id,
    price,
    source_filename,
    loaded_at,
    CURRENT_TIMESTAMP() AS bronze_created_at
FROM parsed_events;