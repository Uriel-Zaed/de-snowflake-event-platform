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
    price,
    source_filename,
    loaded_at,
    bronze_created_at,
    row_num,
    rejection_reason,
    CURRENT_TIMESTAMP() AS rejected_at

FROM {{ ref('int_events_validated') }}
WHERE rejection_reason IS NOT NULL