{{ config(materialized='table') }}

SELECT
    event_id,
    user_id,
    session_id,
    event_type,
    event_timestamp,
    event_date,
    country,
    device,
    product_id,

    CASE
        WHEN event_type = 'purchase' THEN price
        ELSE NULL
    END AS price,

    source_filename,
    loaded_at,
    bronze_created_at,
    CURRENT_TIMESTAMP() AS silver_created_at

FROM {{ ref('int_events_validated') }}
WHERE rejection_reason IS NULL