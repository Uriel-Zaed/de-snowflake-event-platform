{{ config(materialized='table') }}

SELECT
    event_date,

    COUNT(*) AS total_events,
    COUNT(DISTINCT user_id) AS daily_active_users,
    COUNT(DISTINCT session_id) AS total_sessions,

    COUNT_IF(event_type = 'view_product') AS product_views,
    COUNT_IF(event_type = 'add_to_cart') AS add_to_cart_events,
    COUNT_IF(event_type = 'purchase') AS purchase_events,

    ROUND(
        SUM(CASE WHEN event_type = 'purchase' THEN price ELSE 0 END),
        2
    ) AS total_revenue,

    ROUND(
        SUM(CASE WHEN event_type = 'purchase' THEN price ELSE 0 END)
        / NULLIF(COUNT_IF(event_type = 'purchase'), 0),
        2
    ) AS avg_order_value,

    ROUND(
        COUNT_IF(event_type = 'purchase')
        / NULLIF(COUNT(DISTINCT session_id), 0),
        4
    ) AS purchase_events_per_session,

    CURRENT_TIMESTAMP() AS gold_created_at

FROM {{ ref('silver_events_clean') }}
GROUP BY event_date