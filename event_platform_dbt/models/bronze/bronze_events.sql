{{ config(materialized='table') }}

WITH parsed_events AS (

    SELECT
        raw_event:event_id::STRING AS event_id,
        raw_event:user_id::STRING AS user_id,
        raw_event:session_id::STRING AS session_id,
        raw_event:event_type::STRING AS event_type,

        TRY_TO_TIMESTAMP_NTZ(
            raw_event:event_timestamp::STRING
        ) AS event_timestamp,

        raw_event:country::STRING AS country,
        raw_event:device::STRING AS device,
        raw_event:product_id::STRING AS product_id,

        TRY_TO_DECIMAL(
            raw_event:price::STRING,
            10,
            2
        ) AS price,

        source_filename,
        loaded_at

    FROM {{ source('raw', 'raw_events') }}

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

FROM parsed_events