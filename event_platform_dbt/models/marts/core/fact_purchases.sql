{{ config(materialized='table') }}

SELECT
    event_id AS purchase_event_id,
    user_id,
    session_id,
    product_id,
    event_date,
    event_timestamp AS purchase_timestamp,
    country,
    device,
    price AS purchase_amount,

    source_filename,
    loaded_at,
    silver_created_at,
    CURRENT_TIMESTAMP() AS fact_created_at

FROM {{ ref('silver_events_clean') }}
WHERE event_type = 'purchase'