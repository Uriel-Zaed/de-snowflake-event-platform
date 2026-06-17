{{ config(materialized='table') }}

WITH daily_events AS (

    SELECT
        event_date,

        COUNT(*) AS total_events,
        COUNT(DISTINCT user_id) AS daily_active_users,
        COUNT(DISTINCT session_id) AS total_sessions,

        COUNT_IF(event_type = 'view_product') AS product_views,
        COUNT_IF(event_type = 'add_to_cart') AS add_to_cart_events,
        COUNT_IF(event_type = 'purchase') AS purchase_events,

        COUNT_IF(is_product_view) AS product_view_events,
        COUNT_IF(is_add_to_cart) AS add_to_cart_flag_events,
        COUNT_IF(is_purchase) AS purchase_flag_events

    FROM {{ ref('fact_events') }}
    GROUP BY event_date

),

daily_purchases AS (

    SELECT
        event_date,
        COUNT(*) AS purchase_transactions,
        ROUND(SUM(purchase_amount), 2) AS total_revenue,
        ROUND(AVG(purchase_amount), 2) AS avg_order_value
    FROM {{ ref('fact_purchases') }}
    GROUP BY event_date

)

SELECT
    daily_events.event_date,

    daily_events.total_events,
    daily_events.daily_active_users,
    daily_events.total_sessions,

    daily_events.product_views,
    daily_events.add_to_cart_events,
    daily_events.purchase_events,

    COALESCE(daily_purchases.purchase_transactions, 0) AS purchase_transactions,
    COALESCE(daily_purchases.total_revenue, 0) AS total_revenue,
    daily_purchases.avg_order_value,

    ROUND(
        COALESCE(daily_purchases.purchase_transactions, 0)
        / NULLIF(daily_events.total_sessions, 0),
        4
    ) AS purchase_events_per_session,

    CURRENT_TIMESTAMP() AS gold_created_at

FROM daily_events
LEFT JOIN daily_purchases
    ON daily_events.event_date = daily_purchases.event_date