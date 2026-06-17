{{ config(materialized='table') }}

WITH product_catalog AS (

    SELECT
        product_id,
        product_name,
        category,
        brand,
        base_price,
        is_active,
        catalog_updated_at AS catalog_updated_at
    FROM {{ ref('products') }}

),

product_events AS (

    SELECT
        product_id,
        event_timestamp,
        event_date,
        event_type,
        price
    FROM {{ ref('silver_events_clean') }}
    WHERE product_id IS NOT NULL

),

product_event_summary AS (

    SELECT
        product_id,

        MIN(event_timestamp) AS first_seen_at,
        MAX(event_timestamp) AS last_seen_at,
        MIN(event_date) AS first_seen_date,
        MAX(event_date) AS last_seen_date,

        COUNT(*) AS total_product_events,
        COUNT_IF(event_type = 'view_product') AS view_events,
        COUNT_IF(event_type = 'add_to_cart') AS add_to_cart_events,
        COUNT_IF(event_type = 'purchase') AS purchase_events,

        ROUND(AVG(CASE WHEN event_type = 'purchase' THEN price END), 2) AS avg_purchase_price

    FROM product_events
    GROUP BY product_id

)

SELECT
    COALESCE(product_event_summary.product_id, product_catalog.product_id) AS product_id,

    TRY_TO_NUMBER(
        REPLACE(COALESCE(product_event_summary.product_id, product_catalog.product_id), 'product_', '')
    ) AS product_number,

    product_catalog.product_name,
    product_catalog.category,
    product_catalog.brand,
    product_catalog.base_price,
    product_catalog.is_active,

    product_event_summary.first_seen_at,
    product_event_summary.last_seen_at,
    product_event_summary.first_seen_date,
    product_event_summary.last_seen_date,

    COALESCE(product_event_summary.total_product_events, 0) AS total_product_events,
    COALESCE(product_event_summary.view_events, 0) AS view_events,
    COALESCE(product_event_summary.add_to_cart_events, 0) AS add_to_cart_events,
    COALESCE(product_event_summary.purchase_events, 0) AS purchase_events,

    product_event_summary.avg_purchase_price,

    product_catalog.catalog_updated_at,

    CASE
        WHEN product_catalog.product_id IS NULL THEN TRUE
        ELSE FALSE
    END AS missing_from_catalog,

    CURRENT_TIMESTAMP() AS dim_created_at

FROM product_event_summary
FULL OUTER JOIN product_catalog
    ON product_event_summary.product_id = product_catalog.product_id