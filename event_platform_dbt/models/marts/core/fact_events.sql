{{ config(materialized='table') }}

SELECT
    event_id,
    user_id,
    session_id,
    product_id,
    event_date,
    event_timestamp,
    event_type,
    country,
    device,

    CASE
        WHEN event_type = 'purchase' THEN TRUE
        ELSE FALSE
    END AS is_purchase,

    CASE
        WHEN event_type = 'view_product' THEN TRUE
        ELSE FALSE
    END AS is_product_view,

    CASE
        WHEN event_type = 'add_to_cart' THEN TRUE
        ELSE FALSE
    END AS is_add_to_cart,

    price,

    source_filename,
    loaded_at,
    silver_created_at,
    CURRENT_TIMESTAMP() AS fact_created_at

FROM {{ ref('silver_events_clean') }}